require 'chart/dimension_type'

module Chart
  module DimensionTypes
    class DoubleType < DimensionType
      class << self
        def default_bucket_size
          100000
        end

        def signature
          "d"
        end

        def typestr
          "double"
        end

        def match(str)
          str =~ /^-?\d+\.\d+$/
        end
      end

      def deserialize(str)
        Float(str)
      end

      def serialize(value)
        value
      end

      def offset(value, period_str)
        value + deserialize(period_str)
      end

      def pkey(value)
        (value / bucket_size).floor
      end
    end
  end
end
