require 'chart/column'

module Chart
  module Columns
    class VarcharColumn < Column
      class << self
        def default_bucket_size
          nil
        end

        def signature
          "s"
        end

        def typestr
          "varchar"
        end
      end

      def deserialize(str)
        str
      end

      def serialize(value)
        value
      end

      def offset(value, period_str)
        raise "offsets aren't a thing for varchar type"
      end

      def pkey(value)
        raise "using varchar as x isn't yet a thing"
      end
    end
  end
end
