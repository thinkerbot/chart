module Chart
  module Receivers
    class Line
      def call(nxyz)
        nxyz ? [nxyz] : nil
      end
    end
  end
end
