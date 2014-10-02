ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

module TopicHelper
  require 'chart'
  TEST_RUN_TIME = Time.now.strftime("%Y%m%d%H%M%S")

  def test_topic_id(*suffix)
    File.join(TEST_RUN_TIME, __name__, *suffix)
  end

  def execute(*args)
    Chart.conn.execute(*args)
  end

  def setup
    unless Chart::Topic.connected?
      Chart::Topic.connect
    end
    super
  end
end
