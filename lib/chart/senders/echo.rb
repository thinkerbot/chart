module Chart
  module Senders
    class Echo
      def call(data)
        data.each do |nxyz|
          puts nxyz.join(' ')
        end
      end
    end
  end
end
