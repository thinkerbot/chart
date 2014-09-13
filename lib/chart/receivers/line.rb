module Chart
  module Receivers
    class Line
      def call(nxyz)
        if nxyz
          n, x, y, z = nxyz
          [[n, {"dimensions" => ["i", "i", "i"]}, [[x,y,z]]]]
        else
          nil
        end
      end
    end
  end
end
