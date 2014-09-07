module Chart
  class Parser
    DATA_TYPES = "nxyz".chars.to_a
    N_TYPES = DATA_TYPES.length

    attr_reader :defaults
    attr_reader :null_str

    def initialize(options = {})
      @defaults = options.fetch(:defaults) { [] }
      @null_str = options.fetch(:null_str, nil)
    end

    def default(i)
      func = defaults[i]
      func ? func.call : nil
    end

    def resolve(input, i)
      output = input.nil? || input == null_str ? default(i) : input
      output.nil? ? null_str : output
    end
  end
end
