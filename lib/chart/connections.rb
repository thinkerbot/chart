require 'chart/connections/cassandra_connection'

module Chart
  module Connections
    module_function

    def lookup(type)
      case type
      when "cassandra", "default"
        CassandraConnection
      else
        raise "unknown database type: #{type}"
      end
    end
  end
end
