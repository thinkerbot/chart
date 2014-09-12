require 'logging'
require 'cql'
require 'yaml'

module Chart
  class Connection
    PROJECT_ROOT = File.expand_path("../../..", __FILE__)
    LOG_LEVELS   = %w{debug info warn error}
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
          :connections_per_node => config.fetch('connections_per_node', 1),
          :default_consistency  => config.fetch('default_consistency', :quorum),
        }
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

    def client
      @client ||= Cql::Client.connect(config.merge(:logger => logger))
    end

    def close
      @client.close if @client
    end

    def execute(cql, *args)
      statement = @prepared_statements[cql]
      logger.debug { "execute #{cql.inspect} #{args.inspect}"}
      statement.execute(*args)
    end
  end
end