module Chart
  module StorageUtils
    module_function

    def table_name_for(type)
      "#{type}_data"
    end

    def column_names_for(type)
      column_names = Enumerator.new do |y|
        y << 'x'; y << 'y'; y << 'z';
        n = 1
        loop do
          y << "z#{n}"
          n += 1
        end
      end
      type.chars.map {|c| column_names.next }
    end

    def columns_for_type(type, column_type_map)
      column_types = type.chars.map do |c|
        column_type_map[c] or raise "unknown column type: #{c.inspect}"
      end
      column_names_for(type).zip(column_types)
    end
  end
end