module Chart
  class Column
    class << self
      def register_for_storage(storage_type)
        type = "#{storage_type}.#{self.type}"
        TYPES[type] = self
      end

      def type
        raise NotImplementedError
      end

      def lookup(type)
        TYPES[type] or raise "unknown column type: #{type.inspect}"
      end

      def default_bucket_size
        nil
      end
    end
    TYPES = {}

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

    def default_range
      raise NotImplementedError
    end

    def default_range_str
      format(*default_range)
    end

    def format(min, max, boundary = "[]")
      head, tail = boundary.chars.to_a
      "#{head}#{serialize(min)},#{serialize(max)}#{tail}"
    end

    def parse(range_str)
      case range_str
      when /^(\[|\()(.+?),(.+?)(\]|\))$/
        [deserialize($2), deserialize($3), $1 + $4]
      when /^(\[|\()(.+?)~(.+?)(\]|\))$/
        min = deserialize($2)
        max = offset(min, $3)
        min <= max ? [min, max, $1 + $4] : [max, min, $1 + $4]
      when nil
        default_range
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
