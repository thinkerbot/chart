require 'chart/senders/echo'
require 'chart/senders/data'

module Chart
  module Senders
    module_function

    def create(sendr_type, options = {})
      case sendr_type
      when :echo
        Senders::Echo.new(options)
      when :data
        Senders::Data.new(options)
      else
        raise "unknown sendr type: #{sendr_type}"
      end
    end
  end
end
