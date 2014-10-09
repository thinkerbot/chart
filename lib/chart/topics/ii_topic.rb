require 'chart/topic'

module Chart
  module Topics
    class IITopic < Topic
      PROJECTIONS = {
        nil         => [["x", "y"], []],
        "xy"        => [["x", "y"], []],
        "histogram" => [["y", "n"], [:xy_to_y]],
      }
    end
  end
end
