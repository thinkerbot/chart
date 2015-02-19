require 'logging'

module Chart
  class Config
    LOG_LEVELS = %w{debug info warn error fatal}
    Logging.init LOG_LEVELS

    DEFAULT_ENV = {
      'CHART_CONFIG_PATH' => ".chartrc:/etc/chartrc",
      'CHART_CONFIG_FILE' => nil,
    }
    
    DEFAULT_SETTINGS = {}

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

      def register_section(name, defaults)
        defaults.each_pair do |key, value|
          DEFAULT_SETTINGS["#{name}.#{key}"] = value
        end
      end
    end
    register_section('log', {
      "level"           => LOG_LEVELS.index('warn'),
      "format"          => '[%d] %-5l %p %c %m\n',
      "datetime_format" => "%H:%M:%S.%3N",
    })

    attr_reader :settings

    def initialize(settings = {})
      @settings = settings
    end

    def section(name)
      prefix  = "#{name}."
      section = {}
      DEFAULT_SETTINGS.merge(settings).each do |key, value|
        next unless key.index(prefix) == 0
        section[key[prefix.length..-1]] = value
      end
      section
    end

    def set(setting_str)
      key, value = setting_str.split(/\s+/, 2)
      settings[key] = value unless key.to_s.empty?
      self
    end

    def merge(settings)
      dup.merge!(settings)
    end

    def merge!(settings)
      settings.merge!(settings)
      self
    end

    def logger(name)
      config          = section('log')
      level           = config['level']
      format          = config['format']
      datetime_format = config['datetime_format']

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
end
