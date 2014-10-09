require 'chart/connection'
require 'chart/columns'
require 'chart/projection'
require 'json'

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
        return nil if id.nil?

        rows = connection.execute("select id, type, config from topics where id = ?", id)
        row = rows.first
        row ? from_values(row.values) : nil
      end

      def create(id, type = 'ii', config = {})
        topic_class = topic_class_for_type(type)
        topic_class.new(id, config).save
      end

      def from_values(values)
        id, type, config_json = values
        topic_class = topic_class_for_type(type)
        topic_class.new(id, config_json ? JSON.parse(config_json) : {})
      end

      def topic_class_for_type(type)
        Topics.const_get("#{type.upcase}Topic") or raise("no such type: #{type.inspect}")
      end

      def inherited(subclass)
        Topic::TYPES << subclass.type
      end

      def type
        @type ||= self.to_s.split("::").last.downcase.chomp("topic")
      end

      def data_table
        @data_table ||= "#{type}_data"
      end

      def column_names
        @column_names ||= begin
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
      end

      def column_classes
        @column_classes ||= begin
          type.chars.map {|c| Columns.lookup(c) }
        end
      end

      def save_data_query
        @save_data_query ||= "insert into #{data_table} (xp, id, #{column_names.join(', ')}) values (?, ?, #{column_names.map {|s| "?"}.join(', ')})"
      end

      def find_data_queries
        @find_data_queries ||= {
          "[]" => "select #{column_names.join(', ')} from #{data_table} where xp = ? and id = ? and x >= ? and x <= ?",
          "[)" => "select #{column_names.join(', ')} from #{data_table} where xp = ? and id = ? and x >= ? and x <  ?",
          "(]" => "select #{column_names.join(', ')} from #{data_table} where xp = ? and id = ? and x >  ? and x <= ?",
          "()" => "select #{column_names.join(', ')} from #{data_table} where xp = ? and id = ? and x >  ? and x <  ?",
        }
      end
    end
    include Projection

    TYPES = []
    PROJECTIONS = {}

    attr_reader :id
    attr_reader :type
    attr_reader :config

    def initialize(id, config = {})
      @id = id
      @config = config
    end

    def type
      self.class.type
    end

    def connection
      Topic.connection
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
      connection.execute("insert into topics (id, type, config) values (?, ?, ?)", *to_values)
      self
    end

    def save_data(data)
      data.each do |x, *args|
        xp = x_column.pkey(x)
        connection.execute(self.class.save_data_query, xp, id, x, *args)
      end
    end

    def find_data(xmin, xmax, boundary = '[]')
      query = self.class.find_data_queries[boundary] or raise("invalid boundary condition: #{boundary.inspect}")
      data  = []
      x_column.pkeys_for_range(xmin, xmax).each do |xp|
        rows = connection.execute(query, xp, id, xmin, xmax)
        rows.each {|row| data << row.values }
      end
      data
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
        data.sort!
      end

      if options[:headers]
        data.unshift headers
      end

      data
    end

    def write_data(data)
      data = deserialize_data(data)
      save_data(data)
    end

    #
    # Representation
    #

    def deserialize_data(data)
      data.map do |idata|
        odata = []
        columns.each_with_index do |column, i|
          odata[i] = column.deserialize(idata[i])
        end
        odata
      end
    end

    def serialize_data(data)
      data.map do |idata|
        odata = []
        columns.each_with_index do |column, i|
          odata[i] = column.serialize(idata[i])
        end
        odata
      end
    end

    def to_json
      {
        :id => id,
        :type => type,
        :config => config
      }.to_json
    end

    def to_values
      [id, type, config.to_json]
    end
  end
end
