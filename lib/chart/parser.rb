module Chart
  class Parser
    FIELD_SEP = ","

    attr_reader :io
    attr_reader :field_sep

    def initialize(io, options = {})
      @io = io
      @headers = options.fetch(:headers, nil)
      @field_sep = options.fetch(:field_sep, FIELD_SEP)
    end

    def next_fields
      begin
        if line = io.gets
          line.chomp("\n").split(field_sep)
        else
          nil
        end
      rescue IOError
        nil
      end
    end

    def each
      unless block_given?
        return enum_for(:each)
      end

      while fields = next_fields
        yield fields
      end
    end

    def headers
      @headers ||= next_fields
    end

    def data
      @data ||= each.to_a
    end
  end
end
