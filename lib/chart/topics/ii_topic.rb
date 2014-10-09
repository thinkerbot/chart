require 'chart/topic'

module Chart
  module Topics
    class IITopic < Topic
      PROJECTIONS = {
        nil         => :xy,
        "xy"        => :xy,
        "histogram" => :xy_to_y,
      }
    end
  end
end
