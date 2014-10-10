module Chart
  module Projection
    module_function

    def xy_to_y(inputs)
      outputs = Hash.new(0)
      inputs.each do |(x,y)|
        outputs[y] += 1
      end
      outputs.to_a
    end

    def xyz_to_xy_by_z_max(inputs) 
      outputs = []
      inputs.group_by do |(x,y,z)|
        x
      end.each_pair do |(x, xyz_data)|
        outputs << xyz_data.sort_by(&:last).last[0,2]
      end
      outputs
    end
  end
end
