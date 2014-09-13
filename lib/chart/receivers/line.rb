require 'chart/topic'

module Chart
  module Receivers
    class Line
      def initialize
        @cache = {}
      end

      def data_for(topic, new_data = nil)
        current = @cache[topic] ||= []
        @cache[topic] = new_data if new_data
        current
      end

      def call(nxyz)
        if nxyz
          topic, x, y, z = nxyz
          data_for(topic) << [x,y,z]
          [[topic, data_for(topic, [])]]
        else
          nil
        end
      end
    end
  end
end
