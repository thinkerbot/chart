#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/projection'

class Chart::ProjectionTest < Test::Unit::TestCase
  include Chart::Projection

  def test_xy_to_y_counts_by_y
    data = [
      [0, 0],
      [1, 8],
      [2, 1],
      [3, 0],
    ]

    assert_equal [
      [0, 2],
      [1, 1],
      [8, 1],
    ], xy_to_y(data).sort_by(&:first)
  end
end
