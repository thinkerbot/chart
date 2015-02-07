require 'chart/connection'
require 'pg'

module Chart
  module Connections
    class PostgresConnection < Connection
      DEFAULT_OPTIONS = {
        :host     => '127.0.0.1',
        :port     => 5432,
        :dbname   => '',
        :user     => '',
        :password => '',
      }

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
          DEFAULT_OPTIONS
        end

        def command_env(options = {})
          options = default_options.merge(options)

          env = {}
          env["PGPASSWORD"] = options[:password] if options[:password]
          command = ["psql", "-h", options[:host], "-p", options[:port], "-U", options[:user], "-d", options[:dbname]]
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

      def client
        @client ||= begin
          client = PG::Connection.open(options)
          client.set_notice_processor {|msg| logger.info(msg) }
          client
        end
      end

      def prepared_statements
        # prepare the query and give the prepared statement a name (currently
        # same as the query).  the prepare raises an error if if fails.
        @prepared_statements ||= Hash.new do |hash, query|
          name = query
          client.prepare(name, query)
          hash[query] = name
        end
      end

      # Connection

      def close
        @client.close if @client
      end

      def execute(query, *args)
        log_execute(query, args)
        statement = prepared_statements[query]
        client.exec_prepared(statement, args)
      end

      def execute_async(query, *args)
        # don't do async yet...
        execute(query, *args)
      end

      # Topics

      def select_topic_ids
      end

      def select_topic_by_id(id)
      end

      def insert_topic(id, type, config)
      end

      # Data

      def select_data(id, type, pkeys, xmin, xmax, boundary)
      end

      def insert_datum(id, type, pkey, *datum)
      end

      def insert_datum_async(id, type, pkey, *datum)
      end

      # Data Support

      def select_data_queries
      end

      def insert_datum_queries
      end
    end
  end
end