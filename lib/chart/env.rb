require 'logging'
require 'cql'

module Chart
  module Env
    module_function

    LOG_LEVELS          = %w{debug info warn error}
    PROJECT_ROOT        = File.expand_path("../../..", __FILE__)
    ENVIRONMENT         = ENV['CHART_ENV'] || 'development'
    DATABASE_FILE       = ENV['CHART_DATABASE_FILE'] || File.expand_path("config/database.yml", PROJECT_ROOT)
    LOG_LEVEL           = ENV['CHART_LOG_LEVEL'] || LOG_LEVELS.index('warn')
    LOG_FORMAT          = ENV['CHART_LOG_FORMAT'] || '[%d] %-5l %p %c %m\n'
    LOG_DATETIME_FORMAT = ENV['CHART_LOG_DATETIME_FORMAT'] || "%H:%M:%S.%3N"

    Logging.init LOG_LEVELS

    def options(overrides = {})
      { :environment         => ENVIRONMENT,
        :database_file       => DATABASE_FILE,
        :log_level           => LOG_LEVEL,
        :log_format          => LOG_FORMAT,
        :log_datetime_format => LOG_DATETIME_FORMAT,
      }.merge(overrides)
    end

    def setup(options = {})
      options = self.options(options)

      environment = options[:environment]
      config_file = options[:database_file]
      config = load_config(config_file, environment)

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
      logger = Logging.logger[self]

      conn = Cql::Client.connect(config.merge(:logger => logger))
      [conn, config]
    end

    def load_config(config_file = DATABASE_FILE, environment = ENVIRONMENT)
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
end