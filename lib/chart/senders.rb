module Chart
  module Senders
    module_function

    def create(sendr_type)
      case sendr_type
      when :echo
        lambda do |data|
          data.each do |nxyz|
            puts nxyz.join(' ')
          end
        end
      else raise "unknown sendr type: #{sendr_type}"
      end
    end
  end
end
