#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/server'
require 'rack/test'

class Chart::ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ModelHelper

  Config = Chart::Config

  def setup
    super
    Config.delete_all
  end

  def app
    Chart::Server
  end

  def test_index_responds_ok
    get '/'
    assert last_response.ok?
  end

  def test_index_lists_charts_by_id
    Config.create("example/a")
    Config.create("example/b")

    get '/'
    assert last_response.body.include?("example/a")
    assert last_response.body.include?("example/b")
  end
end
