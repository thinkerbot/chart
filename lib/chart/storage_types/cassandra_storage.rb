require 'chart/storage'
require 'cassandra'

module Chart
  module StorageTypes
    class CassandraStorage < Storage
      class << self
        def convert_to_options(configs)
          configs = default_configs.merge(configs)
          {
            :hosts              => configs['hosts'].split(','),
            :port               => configs['port'].to_i,
            :keyspace           => configs['keyspace'],
            :connection_timeout => configs['connection_timeout'].to_i,
          }
        end

        def convert_to_configs(options)
          options = default_options.merge(options)
          {
            'hosts'               => options[:hosts].join(','),
            'port'                => options[:port].to_s,
            'keyspace'            => options[:keyspace],
            'connection_timeout'  => options[:connection_timeout].to_s,
          }
        end

        def default_options
          {
            :hosts    => ['127.0.0.1'],
            :port     => 9042,
            :keyspace => 'default',
            :connection_timeout => 5,
          }
        end

        def command_env(options = {})
          options = default_options.merge(options)

          # don't use port as it is... maybe a different protocol? needs to be 9160
          host = options[:hosts].first
          keyspace = options[:keyspace]

          command = ["cqlsh", host]
          unless keyspace.to_s.strip.empty?
            command += ["-k", keyspace]
          end

          [command.map(&:to_s), {}]
        end

        #
        # helpers
        #

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

      def cluster
        @cluster ||= Cassandra.cluster(options)
      end

      def client
        @client ||= cluster.connect(options[:keyspace])
      end

      def prepared_statements
        @prepared_statements ||= Hash.new {|hash, query| hash[query] = client.prepare(query) }
      end

      # Storage

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
        rows = execute("select type, id, config from topics where id = ?", id)

        if row = rows.first
          type, id, config_json = row.values
          [type, id, JSON.parse(config_json)]
        else
          nil
        end
      end

      def insert_topic(type, id, config)
        execute("insert into topics (type, id, config) values (?, ?, ?)", type, id, config.to_json)
      end

      # Data

      def select_data(type, id, pkeys, xmin, xmax, boundary)
        select_query = select_data_queries[type][boundary] or raise("invalid boundary condition: #{boundary.inspect}")
        data = []
        pkeys.each do |pkey|
          rows = execute(select_query, pkey, id, xmin, xmax)
          rows.each {|row| data << row.values }
        end
        data
      end

      def insert_datum(type, id, pkey, *datum)
        execute(insert_datum_queries[type], pkey, id, *datum)
      end

      def insert_datum_async(type, id, pkey, *datum)
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