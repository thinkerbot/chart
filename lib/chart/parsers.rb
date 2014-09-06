module Chart
  module Parsers
    module_function

    DATA_TYPES = "nxyz".chars.to_a
    N_TYPES = DATA_TYPES.length

    def create(input_type)
      case input_type
      when /^[#{DATA_TYPES}]{1,#{N_TYPES}}$/
        count = input_type.length
        order = DATA_TYPES.map {|c| input_type.index(c) || N_TYPES }.each_with_index

        lambda do |line, defaults, null_str|
          chars = line.split(/\s+/, count)
          order.map do |i, j|
            char = chars[i]
            char.nil? || char == null_str ? (defaults[j] || null_str) : char
          end
        end
      else
        raise "unknown input type: #{input_type}"
      end
    end
  end
end
