#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require File.expand_path('../../../helpers/column_tests', __FILE__)
require 'chart/columns/dcolumn'

class Chart::Columns::DColumnTest < Minitest::Test
  DColumn = Chart::Columns::DColumn
  include ColumnTests

  def column_class
    DColumn
  end

  def serialization_examples
    [
      ["-1.1", -1.1],
      [ "0.0",  0.0],
      [ "1.1",  1.1],
    ]
  end

  def offset_examples
    [
      [1.0, "+1.1", 2.1],
      [2.1, "-1.1", 1.0]
    ]
  end

  def example
    {
      :min => 11.1,
      :max => 18.1,
      :bucket_size => 1,
      :pkey_range => [11, 12, 13, 14, 15, 16, 17, 18],
    }
  end
end
