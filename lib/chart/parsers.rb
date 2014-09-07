require 'chart/parsers/nxyz'

module Chart
  module Parsers
    module_function

    def create(input_type, options = {})
      case input_type
      when Nxyz::PATTERN
        Parsers::Nxyz.create(input_type, options)
      else
        raise "unknown input type: #{input_type}"
      end
    end
  end
end
