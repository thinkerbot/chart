#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/topics/ii_topic'

class Chart::TopicTest < Test::Unit::TestCase
  include TopicHelper
  include Chart::Topics

  Topic = Chart::Topic

  #
  # save_data
  #

  def test_save_data_saves_data_to_data_table
    topic = IITopic.new(test_topic_id)
    topic.save_data [
      [0, 1],
      [1, 2],
    ]

    data = execute("select x, y from ii_data where xp = ? and id = ?", 0, test_topic_id).to_a
    assert_equal [
      {"x" => 0, "y" => 1},
      {"x" => 1, "y" => 2},
    ], data.sort_by {|d| d["x"]}
  end

  #
  # find_data
  #

  def create_ii_topic_with_data
    topic = IITopic.create(test_topic_id)
    topic.save_data([
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
    ])
    topic
  end

  def test_find_data_reads_data_from_data_table_between_min_and_max_inclusive
    topic = create_ii_topic_with_data
    data  = topic.find_data(1, 2)
    assert_equal [
      [1, 2],
      [2, 3],
    ], data.sort_by {|x,y| x }
  end

  def test_find_data_respects_boundary
    topic = create_ii_topic_with_data

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
