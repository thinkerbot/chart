require 'chart/parser'

module Chart
  module Parsers
    class Nxyz < Parser
      class << self
        def create(input_type, options = {})
          new(options.merge(:order => input_type.chars.to_a))
        end
      end
      PATTERN = /^[#{DATA_TYPES}]{1,#{N_TYPES}}$/

      attr_reader :order

      def initialize(options = {})
        @order = options.fetch(:order, DATA_TYPES)
        @count = @order.length
        @order_enum = DATA_TYPES.map {|c| order.index(c) || N_TYPES }.each_with_index
        super
      end

      def call(line)
        chars = line.split(/\s+/, @count)
        @order_enum.map {|j, i| resolve(chars[j], i) }
      end
    end
  end
end
