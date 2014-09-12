#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/topic'

class Chart::TopicTest < Test::Unit::TestCase
  Topic = Chart::Topic

  def test_from_values_deserializes_topic
    topic = Topic.from_values(['example/1', '{"a":"A"}'])
    assert_equal 'example/1', topic.id
    assert_equal 'A', topic['a']
  end

  def test_to_values_serializes_topic
    topic = Topic.new('example/1', 'a' => 'A')
    assert_equal ['example/1', '{"a":"A"}'], topic.to_values
  end
end
