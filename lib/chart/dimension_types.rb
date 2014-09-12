require 'chart/dimension_types/integer_type'

module Chart
  module DimensionTypes
    module_function

    def create(type)
      case type
      when :integer, nil
        IntegerType.new
      else
        raise "unknown dimension type: #{type}"
      end
    end
  end
end
