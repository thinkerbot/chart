require 'chart/model'
require 'json'

module Chart
  class Config < Model
    class << self
      def list
        rows = connection.execute("select id from charts")
        rows.map {|row| row["id"] }
      end

      def find(id)
        rows = connection.execute("select id, configs from charts where id = ?", id)
        row = rows.first
        row ? from_values(row.values) : raise("not found: #{id.inspect}")
      end

      def create(id, configs = {})
        new(id, configs).save
      end

      def delete_all
        connection.execute("truncate charts")
      end

      def from_values(values)
        id, configs_json = values
        new(id, configs_json ? JSON.parse(configs_json) : {})
      end
    end

    attr_reader :id
    attr_reader :configs

    def initialize(id, configs = {})
      @id = id
      @configs = configs
    end

    def [](key)
      configs[key]
    end

    def []=(key, value)
      configs[key] = value
    end

    def save
      connection.execute("insert into charts (id, configs) values (?, ?)", *to_values)
      self
    end

    def to_json
      {
        :id => id,
        :configs => configs
      }.to_json
    end

    def to_values
      [id, configs.to_json]
    end
  end
end
