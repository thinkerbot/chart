require 'chart/storage'
require 'chart/columns'
require 'chart/projection'

module Chart
  class Topic
    class << self
      def inherited(subclass)
        Topic::TYPES << subclass.type
      end

      def type
        @type ||= begin
          prefix = self.to_s.split("::").last.downcase.chomp("topic")
          prefix.empty? ? "ii" : prefix
        end
      end

      def column_classes
        @column_classes ||= begin
          type.chars.map {|c| Columns.lookup(c) }
        end
      end
    end
    include Projection

    TYPES = []
    PROJECTIONS = {}

    attr_reader :storage
    attr_reader :id
    attr_reader :config

    def initialize(storage, id, config = {})
      @storage = storage
      @id = id
      @config = config
    end

    def type
      self.class.type
    end

    def [](key)
      config[key]
    end

    def []=(key, value)
      config[key] = value
    end

    def columns
      @columns ||= self.class.column_classes.map {|c| c.new }
    end

    def x_column
      columns[0]
    end

    #
    # Queries
    #

    def save
      storage.insert_topic(type, id, config)
      self
    end

    def save_data(data)
      data.map do |datum|
        save_datum_async(*datum)
      end.map(&:join)
    end

    def save_datum(x, *args)
      pkey = x_column.pkey(x)
      storage.insert_datum(type, id, pkey, x, *args)
    end

    def save_datum_async(x, *args)
      pkey = x_column.pkey(x)
      storage.insert_datum_async(type, id, pkey, x, *args)
    end

    def find_data(xmin, xmax, boundary = '[]')
      pkeys = x_column.pkeys_for_range(xmin, xmax)
      storage.select_data(type, id, pkeys, xmin, xmax, boundary)
    end

    def projections_for(projection_type)
      self.class::PROJECTIONS[projection_type] or raise("unknown projection: #{projection_type.inspect}")
    end

    def read_data(range_str, options = {})
      range = x_column.parse(range_str)
      data  = find_data(*range)
      data  = serialize_data(data)

      headers, transforms = projections_for(options[:projection])
      transforms.each do |method_name|
        data = send(method_name, data)
      end

      if options[:sort]
        data.sort_by! do |datum|
          [datum[0], datum[1..-1].reverse]
        end
      end

      if options[:headers]
        data.unshift headers
      end

      data
    end

    def write_each(data, options = {})
      unless block_given?
        return enum_for(:write_each, data)
      end

      async = options[:async]
      deserialize_each(data) do |datum|
        res = async ? save_datum_async(*datum) : save_datum(*datum)
        yield res
      end
    end

    def write_data(data, options = {})
      write_each(data).map.to_a
    end

    #
    # Representation
    #

    def deserialize_each(data)
      unless block_given?
        return enum_for(:deserialize_each, data)
      end

      data.each do |idata|
        odata = []
        columns.each_with_index do |column, i|
          odata[i] = column.deserialize(idata[i])
        end
        yield odata
      end
    end

    def deserialize_data(data)
      deserialize_each(data).map.to_a
    end

    def serialize_each(data)
      unless block_given?
        return enum_for(:serialize_each, data)
      end

      data.each do |idata|
        odata = []
        columns.each_with_index do |column, i|
          odata[i] = column.serialize(idata[i])
        end
        yield odata
      end
    end

    def serialize_data(data)
      serialize_each(data).map.to_a
    end

    def to_json
      {
        :id => id,
        :type => type,
        :config => config
      }.to_json
    end
  end
end
