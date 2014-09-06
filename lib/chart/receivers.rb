module Chart
  module Receivers
    module_function

    def create(recvr_type)
      case recvr_type
      when :line
        lambda do |nxyz|
          nxyz ? [nxyz] : nil
        end
      else raise "unknown receiver type: #{recvr_type}"
      end
    end
  end
end
