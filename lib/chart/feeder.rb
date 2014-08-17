module Chart
  class Feeder
    attr_reader :parser

    def initialize(parser)
      @parser = parser
    end

    def next_data
      raise NotImplementedError
    end
  end
end
