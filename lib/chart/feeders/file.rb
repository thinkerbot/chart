require 'chart/feeder'

module Chart
  module Feeders
    class File < Feeder
      def next_data
        if @data
          {}
        else
          @data ||= {
            "headers" => parser.headers,
            "data"    => parser.data,
          }
        end
      end
    end
  end
end
