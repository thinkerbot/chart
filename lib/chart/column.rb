module Chart
  class Column
    class << self
      def default_bucket_size
        nil
      end

      def signature
        raise NotImplementedError
      end

      def typestr
        raise NotImplementedError
      end
    end

    attr_reader :bucket_size

    def initialize(bucket_size = self.class.default_bucket_size)
      @bucket_size = bucket_size
    end

    def deserialize(str)
      raise NotImplementedError
    end

    def serialize(value)
      raise NotImplementedError
    end

    def offset(value, period_str)
      raise NotImplementedError
    end

    def parse(range_str)
      case range_str
      when /^(\[|\()(.+?),(.+?)(\]|\))$/
        [deserialize($2), deserialize($3), $1 + $4]
      when /^(\[|\()(.+?)~(.+?)(\]|\))$/
        min = deserialize($2)
        max = offset(min, $3)
        min <= max ? [min, max, $1 + $4] : [max, min, $1 + $4]
      else
        min = deserialize(range_str)
        [min, min, '[]']
      end
    end

    def pkey(value)
      raise NotImplementedError
    end

    def pkeys_for_range(min, max, boundary = "[]")
      values = []
      current = min
      while current <= max
        values << pkey(current)
        current += bucket_size
      end
      case boundary
      when "[]" then # no change
      when "[)" then values.pop
      when "(]" then values.shift
      when "()" then values.shift; values.pop;
      else raise "invalid boundary: #{boundary.inspect}"
      end
      values
    end
  end
end