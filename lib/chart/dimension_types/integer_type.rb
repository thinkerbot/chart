require 'chart/dimension_type'

module Chart
  module DimensionTypes
    class IntegerType < DimensionType
      class << self
        def default_bucket_size
          100000
        end

        def signature
          "i"
        end

        def typestr
          "varint"
        end

        def match(str)
          str =~ /^\-?\d+$/
        end
      end

      def deserialize(str)
        Integer(str)
      end

      def serialize(value)
        value
      end

      def offset(value, period_str)
        value + deserialize(period_str)
      end

      def pkey(value)
        value / bucket_size
      end
    end
  end
end
