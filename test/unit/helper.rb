ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

module ModelHelper
  def setup
    unless Chart::Topic.connected?
      Chart::Topic.connect
    end
    super
  end
end
