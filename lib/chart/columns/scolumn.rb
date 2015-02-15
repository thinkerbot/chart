require 'chart/column'

module Chart
  module Columns
    class SColumn < Column
      class << self
        def default_bucket_size
          nil
        end
      end

      def deserialize(str)
        str
      end

      def serialize(value)
        value
      end
    end
  end
end
