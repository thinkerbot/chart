require 'chart/connection'
require 'cassandra'

module Chart
  module Connections
    class CassandraConnection < Connection
      class << self
        def load_config(options = {})
          config = super
          {
            :hosts                => config.fetch('hosts'),
            :port                 => config.fetch('port', 9042),
            :keyspace             => config.fetch('keyspace'),
            :connection_timeout   => config.fetch('connection_timeout', 5),
          }
        end

        def connection_command(configs)
          # don't use port as it is... maybe a different protocol? needs to be 9160
          command = ["cqlsh", configs[:hosts][0]]
          if keyspace = configs[:keyspace]
            command += ["-k", keyspace]
          end
          [command.map(&:to_s), {}]
        end

        def table_name_for(type)
          "#{type}_data"
        end

        def column_names_for(type)
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

        def typestrs_for(type)
          type.chars.map do |c|
            case c
            when "d" then "double"
            when "i" then "varint"
            when "t" then "timestamp"
            when "s" then "varchar"
            else raise "unknown column type: #{c.inspect}"
            end
          end
        end

        def columns_for_type(type)
          column_names_for(type).zip(typestrs_for(type))
        end
      end

      attr_reader :prepared_statements

      def initialize(config)
        super
        @prepared_statements = Hash.new {|hash, query| hash[query] = client.prepare(query) }
      end

      def cluster
        @cluster ||= Cassandra.cluster(config.merge(:logger => logger))
      end

      def client
        @client ||= cluster.connect(config[:keyspace])
      end

      # Connection

      def close
        if @client
          @client.close
          @client.nil?
        end

        if @cluster
          @cluster.close
          @cluster.nil?
        end

        self
      end

      def execute(query, *args)
        log_execute(query, args)
        statement = prepared_statements[query]
        client.execute(statement, *args)
      end

      def execute_async(query, *args)
        log_execute(query, args)
        statement = prepared_statements[query]
        client.execute_async(statement, *args)
      end

      # Topics

      def select_topic_ids
        rows = execute("select id from topics")
        rows.map {|row| row["id"] }
      end

      def select_topic_by_id(id)
        rows = execute("select id, type, config from topics where id = ?", id)

        if row = rows.first
          id, type, config_json = row.values
          [id, type, JSON.parse(config_json)]
        else
          nil
        end
      end

      def insert_topic(id, type, config)
        execute("insert into topics (id, type, config) values (?, ?, ?)", id, type, config.to_json)
      end

      # Data

      def select_data(id, type, pkeys, xmin, xmax, boundary)
        select_query = select_data_queries[type][boundary] or raise("invalid boundary condition: #{boundary.inspect}")
        data = []
        pkeys.each do |pkey|
          rows = execute(select_query, pkey, id, xmin, xmax)
          rows.each {|row| data << row.values }
        end
        data
      end

      def insert_datum(id, type, pkey, *datum)
        execute(insert_datum_queries[type], pkey, id, *datum)
      end

      def insert_datum_async(id, type, pkey, *datum)
        execute_async(insert_datum_queries[type], pkey, id, *datum)
      end

      # Data Support

      def select_data_queries
        @select_data_queries ||= Hash.new do |cache, type|
          table_name   = self.class.table_name_for(type)
          column_names = self.class.column_names_for(type)
          cache[type] = {
            "[]" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >= ? and x <= ?",
            "[)" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >= ? and x <  ?",
            "(]" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >  ? and x <= ?",
            "()" => "select #{column_names.join(', ')} from #{table_name} where xp = ? and id = ? and x >  ? and x <  ?",
          }
        end
      end

      def insert_datum_queries
        @insert_datum_queries ||= Hash.new do |cache, type|
          table_name   = self.class.table_name_for(type)
          column_names = self.class.column_names_for(type)
          cache[type]  = "insert into #{table_name} (xp, id, #{column_names.join(', ')}) values (?, ?, #{column_names.map {|s| "?"}.join(', ')})"
        end
      end
    end
  end
end