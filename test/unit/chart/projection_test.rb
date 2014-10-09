#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/projection'

class Chart::ProjectionTest < Test::Unit::TestCase
  include Chart::Projection

  def test_xy_to_y_creates_histogram_data
    data = [
      [0, 1],
      [0, 2],
      [1, 3],
      [3, 4],
    ]

    assert_equal [
      [0, 2],
      [1, 1],
      [3, 1],
    ], xy_to_y(data).sort_by(&:first)
  end
end
