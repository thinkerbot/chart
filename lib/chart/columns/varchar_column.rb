require 'chart/column'

module Chart
  module Columns
    class VarcharColumn < Column
      class << self
        def default_bucket_size
          nil
        end

        def type
          "s"
        end

        def deserialize(str)
          str
        end

        def serialize(value)
          value
        end
      end
      register_for_storage "cassandra"
      register_for_storage "postgres"
    end
  end
end
