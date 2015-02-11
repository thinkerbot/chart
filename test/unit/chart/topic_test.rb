#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require File.expand_path('../../helpers/topic_helper', __FILE__)

class Chart::TopicTest < Minitest::Test
  include TopicHelper
  include Chart::Topics

  def storage_type
    'cassandra'
  end

  def topic_type
    'ii'
  end

  #
  # save_data
  #

  def test_save_data_saves_data_to_data_table
    topic = create_topic(test_id)
    topic.save_data [
      [0, 1],
      [1, 2],
    ]

    data = execute("select x, y from ii_data where xp = ? and id = ?", 0, test_id).to_a
    assert_equal [
      {"x" => 0, "y" => 1},
      {"x" => 1, "y" => 2},
    ], data.sort_by {|d| d["x"]}
  end

  #
  # find_data
  #

  def create_topic_with_data(*args)
    topic = create_topic(*args)
    topic.save_data([
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
    ])
    topic
  end

  def test_find_data_reads_data_from_data_table_between_min_and_max_inclusive
    topic = create_topic_with_data(test_id)
    data  = topic.find_data(1, 2)
    assert_equal [
      [1, 2],
      [2, 3],
    ], data.sort_by {|x,y| x }
  end

  def test_find_data_respects_boundary
    topic = create_topic_with_data(test_id)

    data  = topic.find_data(1, 2, '[]')
    assert_equal [
      [1, 2],
      [2, 3],
    ], data.sort_by {|x,y| x }

    data  = topic.find_data(1, 2, '[)')
    assert_equal [
      [1, 2],
    ], data.sort_by {|x,y| x }

    data  = topic.find_data(1, 2, '(]')
    assert_equal [
      [2, 3],
    ], data.sort_by {|x,y| x }

    data  = topic.find_data(0, 3, '()')
    assert_equal [
      [1, 2],
      [2, 3],
    ], data.sort_by {|x,y| x }
  end
end
