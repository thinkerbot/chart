require 'chart/topic'

module Chart
  module Topics
    class IIITopic < Topic
      PROJECTIONS = {
        nil         => [["x", "y", "z"], []],
        "xyz"       => [["x", "y", "z"], []],
        "xy"        => [["x", "y"],      [:xyz_to_xy_by_z_max]],
        "histogram" => [["y", "n"],      [:xyz_to_xy_by_z_max, :xy_to_y]],
      }
    end
  end
end
