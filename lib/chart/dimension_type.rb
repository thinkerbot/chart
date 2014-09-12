module Chart
  class DimensionType
    class << self
      def default_bucket_size
        nil
      end
    end

    attr_reader :bucket_size

    def initialize(bucket_size = self.class.default_bucket_size)
      @bucket_size = bucket_size
    end

    def signature
      raise NotImplementedError
    end

    def deserialize(str)
      raise NotImplementedError
    end

    def serialize(value)
      raise NotImplementedError
    end

    def pkey(value)
      raise NotImplementedError
    end

    def pkeys_for_range(min, max)
      values = []
      current = min
      while current <= max
        values << pkey(current)
        current += bucket_size
      end
      values
    end
  end
end
