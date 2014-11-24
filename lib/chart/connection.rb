require 'json'
require 'logging'
require 'yaml'

module Chart
  class Connection
    PROJECT_ROOT = File.expand_path("../../..", __FILE__)
    LOG_LEVELS   = %w{debug info warn error fatal}
    Logging.init LOG_LEVELS

    class << self
      def options(overrides = {})
        { :environment         => ENV['RACK_ENV'] || 'development',
          :database_type       => ENV['CHART_DATABASE_TYPE'],
          :database_file       => ENV['CHART_DATABASE_FILE'] || File.expand_path("config/database.yml", PROJECT_ROOT),
          :log_level           => ENV['CHART_LOG_LEVEL'] || LOG_LEVELS.index('warn'),
          :log_format          => ENV['CHART_LOG_FORMAT'] || '[%d] %-5l %p %c %m\n',
          :log_datetime_format => ENV['CHART_LOG_DATETIME_FORMAT'] || "%H:%M:%S.%3N",
          :config              => {},
        }.merge(overrides)
      end

      def setup(options = {})
        options = self.options(options)
        config = load_config(options)

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
        overrides   = options.fetch(:config, {})
        YAML.load_file(config_file).fetch(environment).merge!(overrides)
      end

      def guess_database_type(options = {})
        database_file = options.fetch(:database_file, "default")
        database_name = File.basename(database_file).chomp(File.extname(database_file))
        database_name == "database" ? "default" : database_name
      end
    end

    attr_reader :config
    attr_reader :logger

    def initialize(config)
      @config = config
      @logger = Logging.logger[self]
    end

    # Connection

    def close
      raise NotImplementedError
    end

    def execute(query, *args)
      logger.debug { "execute #{query.inspect} #{args.inspect}"}
    end

    def execute_async(query, *args)
      logger.debug { "execute #{query.inspect} #{args.inspect}"}
    end

    # Topics

    def select_topic_ids
      raise NotImplementedError
    end

    def select_topic_by_id(id)
      raise NotImplementedError
    end

    def insert_topic(id, type, config)
      raise NotImplementedError
    end

    # Data

    def select_data(id, type, pkeys, xmin, xmax, boundary)
      raise NotImplementedError
    end

    def insert_datum(id, type, pkey, *datum)
      raise NotImplementedError
    end

    def insert_datum_async(id, type, pkey, *datum)
      raise NotImplementedError
    end
  end
end