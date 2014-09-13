require 'chart/sender'

module Chart
  module Senders
    class Echo < Sender
      def call(data)
        data.each do |nxyz|
          fields = nxyz.join(' ')
          puts(url ? File.join(url, fields) : fields)
        end
      end
    end
  end
end
