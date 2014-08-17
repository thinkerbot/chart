require 'chart/feeders/line'
require 'chart/feeders/file'

module Chart
  module Feeders
    module_function

    def lookup(style)
      case style
      when :line then Feeders::Line
      when :file then Feeders::File
      else raise "unknown style: #{style.inspect}"
      end
    end
  end
end
        