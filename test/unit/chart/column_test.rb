module ColumnTest
  def column_class
    raise NotImplementedError
  end

  def column
    @column ||= column_class.new
  end

  def serialization_examples
    raise NotImplementedError
  end

  def test_serialization
    serialization_examples.each do |(s, d)|
      assert_equal d, column.deserialize(s),    "deserialize failed: #{s.inspect}"
      assert_equal d, column.deserialize(d),    "double deserialize failed: #{s.inspect}"
      assert_equal s, column.serialize(d).to_s, "serialize failed: #{d.inspect}"
      assert_equal d, column.deserialize(column.serialize(d)),      "deserialized round-trip failed: #{d.inspect}"
      assert_equal s, column.serialize(column.deserialize(s)).to_s, "serialized round-trip failed: #{s.inspect}"
    end
  end

  def offset_examples
    raise NotImplementedError
  end

  def test_offset
    offset_examples.each do |(v, p, e)|
      assert_equal e, column.offset(v, p), "offset failed: #{v.inspect} #{p}"
    end
  end

  def example
    raise NotImplementedError
  end

  def min; example[:min]; end
  def max; example[:max]; end
  def bucket_size; example[:bucket_size]; end
  def min_pkey; example[:min_pkey]; end
  def max_pkey; example[:max_pkey]; end
  def pkey_range; example[:pkey_range]; end

  def range_str(lower_boundary, upper_boundary)
    [lower_boundary, column.serialize(min), "," , column.serialize(max), upper_boundary].join('')
  end

  def period; example[:period] || column.serialize(max - min); end
  def period_str(lower_boundary, upper_boundary)
    [lower_boundary, column.serialize(min), "~", period, upper_boundary].join('')
  end

  def test_parse
    @column = column_class.new(bucket_size)

    assert_equal [min, max, "[]"], column.parse(range_str("[", "]")), "parse range_str []"
    assert_equal [min, max, "[)"], column.parse(range_str("[", ")")), "parse range_str [)"
    assert_equal [min, max, "(]"], column.parse(range_str("(", "]")), "parse range_str (]"
    assert_equal [min, max, "()"], column.parse(range_str("(", ")")), "parse range_str ()"

    assert_equal [min, max, "[]"], column.parse(period_str("[", "]")), "parse period_str []"
    assert_equal [min, max, "[)"], column.parse(period_str("[", ")")), "parse period_str [)"
    assert_equal [min, max, "(]"], column.parse(period_str("(", "]")), "parse period_str (]"
    assert_equal [min, max, "()"], column.parse(period_str("(", ")")), "parse period_str ()"

    assert_equal [min, min, "[]"], column.parse(column.serialize(min)), "parse value"
  end

  def test_pkey
    @column = column_class.new(bucket_size)
    assert_equal pkey_range.first, column.pkey(min)
    assert_equal pkey_range.last,  column.pkey(max)
  end

  def test_pkeys_for_range
    @column = column_class.new(bucket_size)
    assert_equal pkey_range, column.pkeys_for_range(min, max)

    assert_equal pkey_range,        column.pkeys_for_range(min, max, "[]"), "pkeys for boundary []"
    assert_equal pkey_range[0..-2], column.pkeys_for_range(min, max, "[)"), "pkeys for boundary [)"
    assert_equal pkey_range[1..-1], column.pkeys_for_range(min, max, "(]"), "pkeys for boundary (]"
    assert_equal pkey_range[1..-2], column.pkeys_for_range(min, max, "()"), "pkeys for boundary ()"
  end
end
