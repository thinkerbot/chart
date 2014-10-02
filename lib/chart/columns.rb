require 'chart/columns/double_column'
require 'chart/columns/integer_column'
require 'chart/columns/timestamp_column'
require 'chart/columns/varchar_column'

module Chart
  module Columns
    module_function

    def create(type)
      case type
      when DoubleColumn.signature
        DoubleColumn.new
      when IntegerColumn.signature, nil
        IntegerColumn.new
      when TimestampColumn.signature
        TimestampColumn.new
      when VarcharColumn.signature
        VarcharColumn.new
      else
        raise "unknown column type: #{type}"
      end
    end
  end
end
