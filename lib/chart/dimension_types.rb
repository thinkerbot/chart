require 'chart/dimension_types/double_type'
require 'chart/dimension_types/integer_type'
require 'chart/dimension_types/timestamp_type'
require 'chart/dimension_types/varchar_type'

module Chart
  module DimensionTypes
    module_function

    def create(type)
      case type
      when DoubleType.signature
        DoubleType.new
      when IntegerType.signature, nil
        IntegerType.new
      when TimestampType.signature
        TimestampType.new
      when VarcharType.signature
        VarcharType.new
      else
        raise "unknown dimension type: #{type}"
      end
    end
  end
end
