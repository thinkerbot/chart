module Chart
  module Projection
    module_function

    HEADERS = {}

    def xy(input)
      input
    end
    HEADERS[:xy] = ['x', 'y']

    def xy_to_y(input)
      output = Hash.new(0)
      input.each do |(x,y)|
        output[x] += 1
      end
      output.to_a
    end
    HEADERS[:xy_to_y] = ['y', 'n']
  end
end
