require 'chart/connection'

module Chart
  class Model
    class << self
      def connection
        return Model.connection unless self == Model
        @connection || raise("connection is not set")
      end

      def connect(options = {})
        disconnect
        @connection = Connection.setup(options)
        self
      end

      def disconnect
        if connected?
          @connection.close
          @connection = nil
        end
        self
      end

      def connected?
        @connection ? true : false
      end
    end

    def connection
      self.class.connection
    end
  end
end
