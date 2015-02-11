require File.expand_path('../../helpers/storage_helper', __FILE__)
require 'chart/topics'

module TopicHelper
  include StorageHelper

  def topic_type
    raise NotImplementedError
  end

  def topic_class
    Chart::Topics.lookup(topic_type)
  end

  def init_topic(*args)
    topic_class.new(storage, *args)
  end

  def create_topic(*args)
    init_topic(*args).save
  end

  def assert_projection(projection, data, expected)
    topic = create_topic(test_id)
    topic.save_data(data)

    x_values  = data.map(&:first).sort
    range_str = "[#{x_values.first},#{x_values.last}]"
    actual = topic.read_data(range_str, :projection => projection, :sort => true)

    assert_equal expected, actual
  end
end
