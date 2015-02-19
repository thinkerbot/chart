require 'chart/storage'
require 'chart/storage_utils'
require 'json'
autoload :Cassandra, 'cassandra'

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
      end

      COLUMN_TYPE_MAP = {
        Columns::DColumn.type => "double",
        Columns::IColumn.type => "varint",
        Columns::TColumn.type => "timestamp",
        Columns::SColumn.type => "varchar",
      }

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

        @prepared_statements = nil

        self
      end

      def execute(query, *args)
        log_execute(query, args)
        statement = prepared_statements[query]
        client.execute(statement, *args)
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
          rows = execute(select_query, id, pkey, xmin, xmax)
          rows.each {|row| data << row.values }
        end
        data
      end

      def insert_datum(type, id, pkey, *datum)
        execute(insert_datum_queries[type], id, pkey, *datum)
      end

      # Data Support

      def select_data_queries
        @select_data_queries ||= Hash.new do |cache, type|
          table_name   = StorageUtils.table_name_for(type)
          column_names = StorageUtils.column_names_for(type)
          cache[type] = {
            "[]" => "select #{column_names.join(', ')} from #{table_name} where id = ? and xp = ? and x >= ? and x <= ?",
            "[)" => "select #{column_names.join(', ')} from #{table_name} where id = ? and xp = ? and x >= ? and x <  ?",
            "(]" => "select #{column_names.join(', ')} from #{table_name} where id = ? and xp = ? and x >  ? and x <= ?",
            "()" => "select #{column_names.join(', ')} from #{table_name} where id = ? and xp = ? and x >  ? and x <  ?",
          }
        end
      end

      def insert_datum_queries
        @insert_datum_queries ||= Hash.new do |cache, type|
          table_name   = StorageUtils.table_name_for(type)
          column_names = StorageUtils.column_names_for(type)
          cache[type]  = "insert into #{table_name} (id, xp, #{column_names.join(', ')}) values (?, ?, #{column_names.map {|s| "?"}.join(', ')})"
        end
      end
    end
  end
end