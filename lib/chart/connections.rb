module Chart
  module Connections
    module_function
    autoload 'CassandraConnection', 'chart/connections/cassandra_connection'
    autoload 'PostgresConnection', 'chart/connections/postgres_connection'

    def lookup(type)
      case type
      when "cassandra", "default"
        CassandraConnection
      when "postgres"
        PostgresConnection
      else
        raise "unknown database type: #{type}"
      end
    end
  end
end
