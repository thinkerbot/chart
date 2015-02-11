require 'chart/column'

module Chart
  module Columns
    class IntegerColumn < Column
      class << self
        def default_bucket_size
          100000
        end

        def type
          "i"
        end

        def match(str)
          str =~ /^\-?\d+$/
        end
      end
      register nil
      register

      def deserialize(str)
        Integer(str)
      end

      def serialize(value)
        value
      end

      def offset(value, period_str)
        value + deserialize(period_str)
      end

      def default_range
        [0, bucket_size, '[]']
      end

      def pkey(value)
        value / bucket_size
      end
    end
  end
end
