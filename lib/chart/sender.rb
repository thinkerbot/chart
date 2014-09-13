module Chart
  class Sender
    attr_reader :url

    def initialize(options = {})
      @url = options.fetch(:url, nil)
    end

    def call(data)
      raise NotImplementedError
    end
  end
end
