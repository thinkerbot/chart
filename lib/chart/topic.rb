require 'chart/connection'

module Chart
  class Topic
    class << self
      def connection
        @connection || raise("connection is not set")
      end

      def connect(options = {})
        disconnect
        @connection = Connection.setup(options)
        self
      end

      def disconnect
        if connected?
          @connection.close
          @connection = nil
        end
        self
      end

      def connected?
        @connection ? true : false
      end

      def list
        rows = connection.execute("select id from topics")
        rows.map {|row| row["id"] }
      end

      def find(id)
        rows = connection.execute("select id, config from topics where id = ?", id)
        row = rows.first
        row ? from_values(row.values) : nil
      end

      def create(id, config = {})
        new(id, config).save
      end

      def from_values(values)
        id, config_json = values
        new(id, config_json ? JSON.parse(config_json) : {})
      end
    end

    attr_reader :id
    attr_reader :config

    def initialize(id, config = {})
      @id = id
      @config = config
    end

    def connection
      self.class.connection
    end

    def [](key)
      config[key]
    end

    def []=(key, value)
      config[key] = value
    end

    def config=(config)
      @config = config
    end

    #
    # Queries
    #

    def save
      connection.execute("insert into topics (id, config) values (?, ?)", *to_values)
      self
    end

    #
    # Representation
    #

    def to_json
      {
        :id => id,
        :config => config
      }.to_json
    end

    def to_values
      [id, config.to_json]
    end
  end
end
