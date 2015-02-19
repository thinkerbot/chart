#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require File.expand_path('../../../helpers/topic_helper', __FILE__)
require 'chart/storage_types/cassandra_storage'
require 'chart/topics/iii_topic'

class Chart::Topics::IIITopicTest < Minitest::Test
  include TopicHelper

  def storage_type
    'cassandra'
  end

  def topic_type
    'iii'
  end

  #
  # projections
  #

  def test_projection_to_histogram
    assert_projection "histogram", [
      [0, 1, 0],
      [0, 0, 1],
      [1, 1, 2],
      [1, 0, 3],
      [2, 0, 4],
      [2, 8, 5],
    ],[
      [0, 2],
      [8, 1],
    ]
  end

  def test_projection_to_xy_picks_by_max_z
    assert_projection "xy", [
      [0, 1, 0],
      [0, 0, 1],
      [1, 1, 2],
      [1, 0, 3],
      [2, 0, 4],
      [2, 8, 5],
    ], [
      [0, 0],
      [1, 0],
      [2, 8],
    ]
  end

  def test_projection_to_xyz_returns_xyz_data
    assert_projection "xyz", [
      [0, 1, 0],
      [0, 0, 1],
      [1, 1, 2],
      [1, 0, 3],
      [2, 0, 4],
      [2, 8, 5],
    ], [
      [0, 1, 0],
      [0, 0, 1],
      [1, 1, 2],
      [1, 0, 3],
      [2, 0, 4],
      [2, 8, 5],
    ]
  end
end
