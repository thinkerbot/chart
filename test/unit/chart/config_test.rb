#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/config'

class Chart::ConfigTest < Test::Unit::TestCase
  Config = Chart::Config

  def test_from_values_deserializes_config
    config = Config.from_values(['chart/1', '{"a":"A"}'])
    assert_equal 'chart/1', config.id
    assert_equal 'A', config['a']
  end

  def test_to_values_serializes_config
    config = Config.new('chart/1', 'a' => 'A')
    assert_equal ['chart/1', '{"a":"A"}'], config.to_values
  end
end
