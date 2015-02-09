require 'logging'
require 'chart/async_interface'

module Chart
  class Storage
    class << self
      def convert_to_options(configs)
        {}
      end

      def convert_to_configs(options)
        {}
      end

      def default_configs
        convert_to_configs(default_options)
      end

      def default_options
        {}
      end

      def setup(configs = {}, logger = nil)
        options = convert_to_options(configs)
        new(options, logger)
      end

      def command_env(options = {})
        raise NotImplementedError
      end
    end

    attr_reader :options
    attr_reader :logger

    def initialize(options = {}, logger = nil)
      @options = self.class.default_options.merge(options)
      @logger  = logger || Logging.logger[self]
    end

    # Logging

    def log_execute(query, args)
      logger.debug { "execute #{query.inspect} #{args.inspect}"}
    end

    # Storage

    def close
      raise NotImplementedError
    end

    def execute(query, *args)
      raise NotImplementedError
    end

    def execute_async(query, *args)
      res = execute(query, *args)
      AsyncInterface.new(res)
    end

    def command_env
      self.class.command_env(options)
    end

    # Topics

    def select_topic_ids
      raise NotImplementedError
    end

    def select_topic_by_id(id)
      raise NotImplementedError
    end

    def insert_topic(type, id, config)
      raise NotImplementedError
    end

    # Data

    def select_data(type, id, pkeys, xmin, xmax, boundary)
      raise NotImplementedError
    end

    def insert_datum(type, id, pkey, *datum)
      raise NotImplementedError
    end

    def insert_datum_async(type, id, pkey, *datum)
      raise NotImplementedError
    end
  end
end