ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.setup

require 'minitest/autorun'

module TopicHelper
  require 'chart'
  TEST_RUN_TIME = Time.now.strftime("%Y%m%d%H%M%S")

  def test_topic_id(*suffix)
    File.join(TEST_RUN_TIME, name, *suffix)
  end

  def execute(*args)
    Chart.conn.execute(*args)
  end

  def setup
    unless Chart::Topic.connected?
      Chart::Topic.connect
      at_exit { Chart::Topic.connection.close }
    end
    super
  end

  def topic_class
    raise NotImplementedError
  end

  def assert_projection(projection, data, expected)
    topic = topic_class.create(test_topic_id)
    topic.save_data(data)

    x_values  = data.map(&:first).sort
    range_str = "[#{x_values.first},#{x_values.last}]"
    actual = topic.read_data(range_str, :projection => projection, :sort => true)

    assert_equal expected, actual
  end
end

module EnvMethods
  module_function

  # Sets the specified ENV variables and returns the *current* env.
  # If replace is true, current ENV variables are replaced; otherwise
  # the new env variables are simply added to the existing set.
  def set_env(env={}, replace=false)
    current_env = {}
    ENV.each_pair do |key, value|
      current_env[key] = value
    end

    ENV.clear if replace

    env.each_pair do |key, value|
      if value.nil?
        ENV.delete(key)
      else
        ENV[key] = value
      end
    end if env

    current_env
  end

  # Sets the specified ENV variables for the duration of the block.
  # If replace is true, current ENV variables are replaced; otherwise
  # the new env variables are simply added to the existing set.
  #
  # Returns the block return.
  def with_env(env={}, replace=false)
    current_env = nil
    begin
      current_env = set_env(env, replace)
      yield
    ensure
      if current_env
        set_env(current_env, true)
      end
    end
  end
end
