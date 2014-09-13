module Chart
  module Receivers
    class Line
      def initialize
        @configs = {}
        @cache = {}
      end

      def config_for(topic)
        @configs[topic] ||= guess_config_for(topic)
      end

      def guess_config_for(topic)
        data = data_for(topic)
        dimensions = data.first.map do |field|
          case field
          when /^\d+$/ then "i"
          when /^\d+\.\d+$/ then "d"
          when /^\d\d\d\d-\d\d-\d\dT\d\d:\d\d:\d\d(?:\.\d+)?(?:Z|[+-]\d\d:\d\d)$/ then "t"
          else "s"
          end
        end
        {"dimensions" => dimensions}
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
          [[topic, config_for(topic), data_for(topic, [])]]
        else
          nil
        end
      end
    end
  end
end
