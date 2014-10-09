#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/topics/ii_topic'

class Chart::TopicTest < Test::Unit::TestCase
  include TopicHelper
  include Chart::Topics

  Topic = Chart::Topic

  def test_from_values_deserializes_topic
    topic = Topic.from_values([test_topic_id, 'ii', '{"a":"A"}'])
    assert_equal test_topic_id, topic.id
    assert_equal 'ii', topic.type
    assert_equal 'A', topic['a']
  end

  def test_to_values_serializes_topic
    topic = IITopic.new(test_topic_id, 'a' => 'A')
    assert_equal [test_topic_id, 'ii', '{"a":"A"}'], topic.to_values
  end

  # data_table
  #
  
  def test_data_table_is_derived_from_type
    assert_equal "ii_data", IITopic.data_table
  end

  #
  # column_names
  #

  def test_column_names_are_derived_from_type
    assert_equal ["x", "y"], IITopic.column_names
  end

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
