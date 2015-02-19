require 'chart/storage'
require 'chart/storage_utils'
require 'json'
autoload :PG, 'pg'

module Chart
  module StorageTypes
    class PostgresStorage < Storage
      class << self
        def convert_to_options(configs)
          configs = default_configs.merge(configs)
          {
            :host     => configs['host'],
            :port     => configs['port'].to_i,
            :dbname   => configs['database'],
            :user     => configs['username'],
            :password => configs['password'],
          }
        end

        def convert_to_configs(options)
          options = default_options.merge(options)
          {
            'host'     => options[:host],
            'port'     => options[:port].to_s,
            'database' => options[:dbname],
            'username' => options[:user],
            'password' => options[:password],
          }
        end

        def default_options
          {
            :host     => '127.0.0.1',
            :port     => 5432,
            :dbname   => '',
            :user     => '',
            :password => '',
          }
        end

        def command_env(options = {})
          options = default_options.merge(options)

          env = {}
          env["PGPASSWORD"] = options[:password] if options[:password]
          command = ["psql", "-h", options[:host], "-p", options[:port], "-U", options[:user], "-d", options[:dbname]]
          [command.map(&:to_s), {}]
        end
      end

      COLUMN_TYPE_MAP = {
        Columns::DColumn.type => "double",
        Columns::IColumn.type => "integer",
        Columns::TColumn.type => "timestamp",
        Columns::SColumn.type => "varchar",
      }

      def client
        @client ||= begin
          client = PG::Connection.open(options)
          client.type_map_for_results = PG::BasicTypeMapForResults.new(client)
          client.type_map_for_queries = PG::BasicTypeMapForQueries.new(client)
          client.set_notice_processor {|msg| logger.info(msg) }
          client
        end
      end

      def prepared_statements
        # prepare the query and give the prepared statement a name (currently
        # same as the query).  the prepare raises an error if if fails.
        @prepared_statements ||= Hash.new do |hash, query|
          name = "chart-#{hash.length}"
          client.prepare(name, query)
          hash[query] = name
        end
      end

      # Storage

      def close
        @client.close if @client
        @prepared_statements = nil
        self
      end

      def start_transaction
        client.exec("BEGIN")
      end

      def end_transaction
        client.exec("COMMIT")
      end

      def execute(query, *args)
        log_execute(query, args)
        statement = prepared_statements[query]
        client.exec_prepared(statement, args)
      end

      # Topics

      def select_topic_ids
        rows = execute("select id from topics")
        rows.map {|row| row["id"] }
      end

      def select_topic_by_id(id)
        rows = execute("select type, id, config from topics where id = $1", id)

        if row = rows.first
          type, id, config_json = row.values
          [type, id, JSON.parse(config_json)]
        else
          nil
        end
      end

      def insert_topic(type, id, config)
        execute("insert into topics (type, id, config) values ($1, $2, $3)", type, id, config.to_json)
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
            "[]" => "select #{column_names.join(', ')} from #{table_name} where id = $1 and xp = $2 and x >= $3 and x <= $4 order by x desc",
            "[)" => "select #{column_names.join(', ')} from #{table_name} where id = $1 and xp = $2 and x >= $3 and x <  $4 order by x desc",
            "(]" => "select #{column_names.join(', ')} from #{table_name} where id = $1 and xp = $2 and x >  $3 and x <= $4 order by x desc",
            "()" => "select #{column_names.join(', ')} from #{table_name} where id = $1 and xp = $2 and x >  $3 and x <  $4 order by x desc",
          }
        end
      end

      def insert_datum_queries
        @insert_datum_queries ||= Hash.new do |cache, type|
          table_name   = StorageUtils.table_name_for(type)
          column_names = StorageUtils.column_names_for(type)
          cache[type]  = "insert into #{table_name} (id, xp, #{column_names.join(', ')}) values ($1, $2, #{column_names.each_with_index.map {|s, i| "$#{i + 3}"}.join(', ')})"
        end
      end
    end
  end
end