require 'chart/columns/double_column'
require 'chart/columns/integer_column'
require 'chart/columns/timestamp_column'
require 'chart/columns/varchar_column'

module Chart
  module Columns
    module_function

    def lookup(type)
      case type
      when DoubleColumn.signature
        DoubleColumn
      when IntegerColumn.signature, nil
        IntegerColumn
      when TimestampColumn.signature
        TimestampColumn
      when VarcharColumn.signature
        VarcharColumn
      else
        raise "unknown column type: #{type}"
      end
    end
  end
end
