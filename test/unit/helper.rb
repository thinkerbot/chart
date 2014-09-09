ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

module ModelHelper
  def setup
    unless Chart::Model.connected?
      Chart::Model.connect
    end
    super
  end
end
