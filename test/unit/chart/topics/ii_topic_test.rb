#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require 'chart/topics/ii_topic'

class Chart::Topics::IITopicTest < Test::Unit::TestCase
  include TopicHelper
  include Chart::Topics

  def topic_class
    IITopic
  end

  #
  # projections
  #

  def test_projection_to_xy
    assert_projection "xy", [
      [0, 1],
      [0, 2],
      [1, 3],
      [3, 4],
    ], [
      [0, 1],
      [0, 2],
      [1, 3],
      [3, 4],
    ]
  end

  def test_projection_to_histogram
    assert_projection "histogram", [
      [0, 0],
      [1, 8],
      [2, 1],
      [3, 0],
    ],[
      [0, 2],
      [1, 1],
      [8, 1]
    ]
  end
end
