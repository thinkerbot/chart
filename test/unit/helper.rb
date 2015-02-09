ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.setup

require 'minitest/autorun'

CONTEXTS = Hash.new do |hash, type|
  config_file = File.expand_path("../../../config/test/#{type}", __FILE__)
  context     = Chart::Context.create(
    :config_path => nil,
    :config_file => config_file,
    :settings    => [],
  )
  at_exit { context.teardown }
  hash[type] = context
end

module TopicHelper
  require 'chart'
  TEST_RUN_TIME = Time.now.strftime("%Y%m%d%H%M%S")

  def test_topic_id(*suffix)
    File.join(TEST_RUN_TIME, name, *suffix)
  end

  def context
    @context ||= CONTEXTS[:cassandra]
  end

  def storage
    context.storage
  end

  def execute(*args)
    storage.execute(*args)
  end

  def topic_class
    Chart::Topic
  end

  def list(*args)
    context.list(*args)
  end

  def find(*args)
    context.find(*args)
  end

  def create(*args)
    context.create(topic_class.type, *args)
  end

  def assert_projection(projection, data, expected)
    topic = create(test_topic_id)
    topic.save_data(data)

    x_values  = data.map(&:first).sort
    range_str = "[#{x_values.first},#{x_values.last}]"
    actual = topic.read_data(range_str, :projection => projection, :sort => true)

    assert_equal expected, actual
  end
end
