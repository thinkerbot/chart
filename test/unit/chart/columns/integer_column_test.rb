#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require File.expand_path('../../../helpers/column_tests', __FILE__)
require 'chart/columns/integer_column'

class Chart::Columns::IntegerColumnTest < Minitest::Test
  IntegerColumn = Chart::Columns::IntegerColumn
  include ColumnTests

  def column_class
    IntegerColumn
  end

  def serialization_examples
    [
      ["-10", -10],
      [ "-1",  -1],
      [  "0",   0],
      [  "1",   1],
      [ "10",  10],
    ]
  end

  def offset_examples
    [
      [1, "+1", 2],
      [2, "-1", 1]
    ]
  end

  def example
    {
      :min => 10,
      :max => 80,
      :bucket_size => 10,
      :pkey_range => [1, 2, 3, 4, 5, 6, 7, 8],
    }
  end
end
