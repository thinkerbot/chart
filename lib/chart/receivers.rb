require 'chart/receivers/line'

module Chart
  module Receivers
    module_function

    def create(recvr_type)
      case recvr_type
      when :line
        Receivers::Line.new
      else
        raise "unknown receiver type: #{recvr_type}"
      end
    end
  end
end
