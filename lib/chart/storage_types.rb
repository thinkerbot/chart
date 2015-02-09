module Chart
  module StorageTypes
    module_function
    autoload 'CassandraStorage', 'chart/storage_types/cassandra_storage'
    autoload 'PostgresStorage', 'chart/storage_types/postgres_storage'

    def lookup(type)
      case type
      when "cassandra"
        CassandraStorage
      when "postgres"
        PostgresStorage
      else
        raise "unknown storage type: #{type}"
      end
    end
  end
end
