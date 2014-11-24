require 'json'
require 'logging'
require 'cassandra'
require 'yaml'

module Chart
  class Connection
    PROJECT_ROOT = File.expand_path("../../..", __FILE__)
    LOG_LEVELS   = %w{debug info warn error fatal}
    Logging.init LOG_LEVELS

    class << self
      def options(overrides = {})
        { :environment         => ENV['RACK_ENV'] || 'development',
          :database_file       => ENV['CHART_DATABASE_FILE'] || File.expand_path("config/database.yml", PROJECT_ROOT),
          :log_level           => ENV['CHART_LOG_LEVEL'] || LOG_LEVELS.index('warn'),
          :log_format          => ENV['CHART_LOG_FORMAT'] || '[%d] %-5l %p %c %m\n',
          :log_datetime_format => ENV['CHART_LOG_DATETIME_FORMAT'] || "%H:%M:%S.%3N",
        }.merge(overrides)
      end

      def setup(options = {})
        options = self.options(options)

        overrides = options.fetch(:overrides, {})
        config = load_config(options)
        config.merge!(overrides)

        level  = options[:log_level]
        format = options[:log_format]
        datetime_format = options[:log_datetime_format]

        if level.to_s =~ /^\d$/
          level = level.to_i
        else
          level_index = LOG_LEVELS.index(level.to_s.downcase) or raise "no such log level: #{level.inspect}"
          level = level_index
        end

        min_level, max_level = 0, LOG_LEVELS.length
        level = min_level if level < min_level
        level = max_level if level > max_level

        layout = Logging.layouts.pattern(:pattern => format, :date_pattern => datetime_format)
        Logging.appenders.stderr.layout = layout

        logger = Logging.logger[name]
        logger.level = level
        logger.appenders = [:stderr]

        new(config)
      end

      def load_config(options = {})
        environment = options.fetch(:environment)   { self.options[:environment] }
        config_file = options.fetch(:database_file) { self.options[:database_file] }
        config = YAML.load_file(config_file).fetch(environment)
        {
          :hosts                => config.fetch('hosts'),
          :port                 => config.fetch('port', 9042),
          :keyspace             => config.fetch('keyspace'),
          :connection_timeout   => config.fetch('connection_timeout', 5),
        }
      end

      def table_name_for(type)
        "#{type}_data"
      end

      def column_names_for(type)
        column_names = Enumerator.new do |y|
          y << 'x'; y << 'y'; y << 'z';
          n = 1
          loop do
            y << "z#{n}"
            n += 1
          end
        end
        type.chars.map {|c| column_names.next }
      end

      def typestrs_for(type)
        type.chars.map do |c|
          case c
          when "d" then "double"
          when "i" then "varint"
          when "t" then "timestamp"
          when "s" then "varchar"
          else raise "unknown column type: #{c.inspect}"
          end
        end
      end

      def columns_for_type(type)
        column_names_for(type).zip(typestrs_for(type))
      end
    end

    attr_reader :config
    attr_reader :logger
    attr_reader :prepared_statements

    def initialize(config)
      @config = config
      @logger = Logging.logger[self]
      @prepared_statements = Hash.new {|hash, cql| hash[cql] = client.prepare(cql) }
    end

    def cluster
      @cluster ||= Cassandra.connect(config.merge(:logger => logger))
    end

    def client
      @client ||= cluster.connect(config[:keyspace])
    end

    # Connection

    def close
      @client.close if @client
    end

    def execute(cql, *args)
      statement = @prepared_statements[cql]
      logger.debug { "execute #{cql.inspect} #{args.inspect}"}
      client.execute(statement, *args)
    end

    def execute_async(cql, *args)
      statement = @prepared_statements[cql]
      logger.debug { "execute #{cql.inspect} #{args.inspect}"}
      client.execute_async(statement, *args)
    end

    # Topics

    def select_topic_ids
      rows = execute("select id from topics")
      rows.map {|row| row["id"] }
    end

    def select_topic_by_id(id)
      rows = execute("select id, type, config from topics where id = ?", id)

      if row = rows.first
        id, type, config_json = row.values
        [id, type, JSON.parse(config_json)]
      else
        nil
      end
    end

    def insert_topic(id, type, config)
      execute("insert into topics (id, type, config) values (?, ?, ?)", id, type, config.to_json)
    end

    # Data support

    def select_data_queries
      @select_data_queries ||= Hash.new do |cache, type|
        table_name   = self.class.table_name_for(type)
        column_names = self.class.column_names_for(type)
        cache[type] = {
          "[]" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >= ? and x <= ?",
          "[)" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >= ? and x <  ?",
          "(]" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >  ? and x <= ?",
          "()" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >  ? and x <  ?",
        }
      end
    end

    def insert_datum_queries
      @insert_datum_queries ||= Hash.new do |cache, type|
        table_name   = self.class.table_name_for(type)
        column_names = self.class.column_names_for(type)
        cache[type]  = "insert into #{table_name} (xp, id, #{column_names.join(', ')}) values (?, ?, #{column_names.map {|s| "?"}.join(', ')})"
      end
    end

    # Data

    def select_data(id, type, pkeys, xmin, xmax, boundary)
      select_query = select_data_queries[type][boundary] or raise("invalid boundary condition: #{boundary.inspect}")
      data = []
      pkeys.each do |pkey|
        rows = execute(select_query, pkey, id, xmin, xmax)
        rows.each {|row| data << row.values }
      end
      data
    end

    def insert_datum(id, type, pkey, *datum)
      execute(insert_datum_queries[type], pkey, id, *datum)
    end

    def insert_datum_async(id, type, pkey, *datum)
      execute_async(insert_datum_queries[type], pkey, id, *datum)
    end
  end
end