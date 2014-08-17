require 'chart/feeder'

module Chart
  module Feeders
    class Line < Feeder
      def next_data
        headers = parser.headers
        if fields = parser.next_fields
          {
            "headers" => headers,
            "data"    => [fields],
          }
        else
          {}
        end
      end
    end
  end
end
