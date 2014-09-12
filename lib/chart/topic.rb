require 'chart/connection'
require 'chart/dimension_types'

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

      def delete_all
        connection.execute("truncate topics")
        connection.execute("truncate iii_data")
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
      @dimension = nil
      @dimension_signature = nil
      @data_table = nil
    end

    #
    # Dimensions
    #

    def dimensions
      @dimensions ||= begin
        dimension_types = config.fetch(:dimensions, [nil, nil, nil])
        dimension_types.map do |dimension_type|
          DimensionTypes.create(dimension_type)
        end
      end
    end

    def dimension_signature
      @dimension_signature ||= @dimensions.map(&:signature).join
    end

    def x_type
      dimensions[0]
    end

    def y_type
      dimensions[1]
    end

    def z_type
      dimensions[2]
    end

    #
    # Queries
    #

    def data_table
      @data_table ||= "#{dimension_signature}_data"
    end

    def save
      connection.execute("insert into topics (id, config) values (?, ?)", *to_values)
      self
    end

    def find_data(xmin, xmax)
      data = []
      x_type.pkeys_for_range(xmin, xmax).each do |xp|
        rows = connection.execute("select x, y, z from #{data_table} where xp = ? and id = ? and x > ? and x <= ?", xp, id, xmin, xmax)
        rows.each {|row| data << row.values }
      end
      data
    end

    def deserialize_data(data)
      data.map do |idata|
        odata = []
        dimensions.each_with_index do |dim, i|
          odata[i] = dim.deserialize(idata[i])
        end
        odata
      end
    end

    def save_data(data)
      data.each do |(x, y, z)|
        xp = x_type.pkey(x)
        connection.execute("insert into #{data_table} (xp, id, x, y, z) values (?, ?, ?, ?, ?)", xp, id, x, y, z)
      end
    end

    def serialize_data(data)
      data.map do |idata|
        odata = []
        dimensions.each_with_index do |dim, i|
          odata[i] = dim.serialize(idata[i])
        end
        odata
      end
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
