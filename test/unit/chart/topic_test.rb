#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/topic'

class Chart::TopicTest < Test::Unit::TestCase
  include TopicHelper

  Topic = Chart::Topic

  def test_from_values_deserializes_topic
    topic = Topic.from_values([test_topic_id, '{"a":"A"}'])
    assert_equal test_topic_id, topic.id
    assert_equal 'A', topic['a']
  end

  def test_to_values_serializes_topic
    topic = Topic.new(test_topic_id, 'a' => 'A')
    assert_equal [test_topic_id, '{"a":"A"}'], topic.to_values
  end
end
