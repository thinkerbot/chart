#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require File.expand_path('../../column_test', __FILE__)
require 'chart/columns/timestamp_column'

class Chart::Columns::TimestampColumnTest < Test::Unit::TestCase
  TimestampColumn = Chart::Columns::TimestampColumn
  include ColumnTest

  def column_class
    TimestampColumn
  end

  def serialization_examples
    [
      ["2010-01-01T01:02:03Z", Time.iso8601("2010-01-01T01:02:03Z")],
    ]
  end

  def offset_examples
    [
      [Time.iso8601("2010-01-01T00:00:00Z"), "1hr 2min 3sec", Time.iso8601("2010-01-01T01:02:03Z")],
      [Time.iso8601("2010-01-01T01:02:03Z"), "-1hr -2min -3sec", Time.iso8601("2010-01-01T00:00:00Z")]
    ]
  end

  def example
    {
      :min => Time.iso8601("2010-01-01T00:00:00Z"),
      :max => Time.iso8601("2010-01-02T00:00:00Z"),
      :period => "1day",
      :bucket_size => 4.hours.to_i,
      :pkey_range => [87660, 87661, 87662, 87663, 87664, 87665, 87666],
    }
  end
end
