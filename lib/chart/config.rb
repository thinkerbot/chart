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
        row ? from_values(row.values) : nil
      end

      def create(id, configs = {})
        new(id, configs).save
      end

      def delete_all
        connection.execute("truncate charts")
        connection.execute("truncate chart_data")
      end

      def from_values(values)
        id, configs_json = values
        new(id, configs_json ? JSON.parse(configs_json) : {})
      end
    end

    attr_reader :id
    attr_accessor :configs

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

    def calc_xp(x)
      x / 100000
    end

    def calc_xps(xmin, xmax)
      calc_xp(xmin).upto(calc_xp(xmax))
    end

    def find_data(n, xmin, xmax)
      data = []
      calc_xps(xmin, xmax).each do |xp|
        rows = connection.execute("select n, x, y, z from chart_data where xp = ? and id = ? and n = ? and x > ? and x <= ?", xp, id, n, xmin, xmax)
        rows.each {|row| data << row.values }
      end
      data
    end

    def save_data(data)
      data.each do |n, x, y, z|
        xp = calc_xp(x)
        connection.execute("insert into chart_data (xp, id, n, x, y, z) values (?, ?, ?, ?, ?, ?)", xp, id, n, x, y, z)
      end
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
