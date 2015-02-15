require 'chart/column'

module Chart
  module Columns
    class DoubleColumn < Column
      class << self
        def default_bucket_size
          100000
        end

        def type
          "d"
        end

        def match(str)
          str =~ /^-?\d+\.\d+$/
        end

        def deserialize(str)
          Float(str)
        end

        def serialize(value)
          value
        end
      end
      register_for_storage "cassandra"
      register_for_storage "postgres"

      def offset(value, period_str)
        value + deserialize(period_str)
      end

      def default_range
        [0.0, bucket_size, '[]']
      end

      def pkey(value)
        (value / bucket_size).floor
      end
    end
  end
end
