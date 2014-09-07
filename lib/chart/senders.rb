require 'chart/senders/echo'

module Chart
  module Senders
    module_function

    def create(sendr_type)
      case sendr_type
      when :echo
        Senders::Echo.new
      else
        raise "unknown sendr type: #{sendr_type}"
      end
    end
  end
end
