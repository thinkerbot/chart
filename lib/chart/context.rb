require 'chart/storage_types'
require 'logging'
require 'chart/topics'

module Chart
  class Context
    LOG_LEVELS = %w{debug info warn error fatal}
    Logging.init LOG_LEVELS

    DEFAULT_ENV = {
      'CHART_CONFIG_PATH' => ".chartrc:/etc/chartrc",
      'CHART_CONFIG_FILE' => nil,
    }

    DEFAULT_SETTINGS = {
      "storage.type"        => "default",
      "log.level"           => LOG_LEVELS.index('warn'),
      "log.format"          => '[%d] %-5l %p %c %m\n',
      "log.datetime_format" => "%H:%M:%S.%3N",
    }
    
    class << self
      def options(overrides = {})
        {
          :config_path => ENV['CHART_CONFIG_PATH'] || DEFAULT_ENV['CHART_CONFIG_PATH'],
          :config_file => ENV['CHART_CONFIG_FILE'] || DEFAULT_ENV['CHART_CONFIG_FILE'],
          :settings    => [],
        }.merge(overrides)
      end

      def create(options = {})
        options = self.options(options)
        config = new

        config_path = options[:config_path]
        config_file = options[:config_file]

        config_files = glob(config_path) + [config_file]
        config_files.compact.each do |file|
          File.open(file) do |io|
            io.each_line do |line|
              setting_str = line.sub(/#.*/, "").strip
              config.set(setting_str)
            end
          end
        end

        settings = options[:settings]
        settings.each do |setting_str|
          config.set(setting_str)
        end

        config
      end

      def glob(paths)
        unless paths.kind_of?(Array)
          paths = paths.to_s.split(":")
        end
        config_files = []

        paths.each do |path|
          if path[0] == '/'
            config_files << path if File.file?(path)
          else
            dirs = Dir.pwd.split("/")
            until dirs.empty?
              full_path = File.join(*dirs, path)
              if File.file?(full_path)
                config_files << full_path
                break
              else
                dirs.pop
              end
            end
          end
        end
        config_files
      end
    end

    attr_reader :settings

    def initialize(overrides = {})
      @settings = DEFAULT_SETTINGS.merge(overrides)
      @storage = nil
      @loggers = {}
    end

    def configs(*keys)
      prefix  = keys.join('.') + '.'
      configs = {}
      settings.each do |key, value|
        next unless key.index(prefix) == 0
        configs[key[prefix.length..-1]] = value
      end
      configs
    end

    def set(setting_str)
      key, value = setting_str.split(/\s+/, 2)
      settings[key] = value unless key.to_s.empty?
      teardown
    end

    def merge(settings)
      dup.merge!(settings)
    end

    def merge!(settings)
      settings.merge!(settings)
      teardown
      self
    end

    def teardown
      @storage.close if @storage
      @storage = nil
      @loggers.clear
      self
    end

    def storage
      @storage ||= begin
        storage_type  = settings['storage.type']
        storage_class = StorageTypes.lookup(storage_type)
        
        configs = self.configs('storage')
        logger  = self.logger(storage_class)
        
        storage_class.setup(configs, logger)
      end
    end

    def logger(name)
      @loggers[name] ||= begin
        level           = settings['log.level']
        format          = settings['log.format']
        datetime_format = settings['log.datetime_format']

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
        logger
      end
    end

    #
    # API
    #

    def list
      storage.select_topic_ids
    end

    def find(id)
      return nil if id.nil?

      type, id, config = storage.select_topic_by_id(id)
      if type
        topic_class = Topics.lookup(type)
        topic_class.new(storage, id, config)
      else
        nil
      end
    end

    def create(type, id, config = {})
      topic_class = Topics.lookup(type)
      topic_class.new(storage, id, config).save
    end
  end
end
