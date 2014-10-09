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

  end
end
