require 'chart/dimension_type'
require 'timeseries/period'
Time.zone = 'UTC'

module Chart
  module DimensionTypes
    class TimestampType < DimensionType
      class << self
        def default_bucket_size
          1.day.to_i
        end

        def signature
          "t"
        end

        def typestr
          "timestamp"
        end

        def match(str)
          (Time.iso8601(str) rescue false) ? true : false
        end
      end

      def deserialize(str)
        Time.iso8601(str)
      end

      def serialize(value)
        value.in_time_zone.iso8601
      end

      def offset(value, period_str)
        period = Timeseries::Period.parse(period_str)
        value.advance(period)
      end

      def pkey(value)
        value.to_i / bucket_size
      end
    end
  end
end
