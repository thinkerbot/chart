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

  #
  # list
  #

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

  #
  # show
  #

  def test_get_existing_chart_returns_ok
    Config.create("example/a")
    get '/example/a'
    assert last_response.ok?
  end

  def test_get_non_existant_chart_returns_404
    get '/example/a'
    assert_equal 404, last_response.status
  end

  #
  # create/update configs
  #

  ## config

  def test_post_to_chart_id_creates_chart
    assert_equal nil, Config.find("example/a")
    post '/example/a'
    assert_equal "example/a", Config.find("example/a").id
  end

  def test_post_to_chart_id_with_configs_creates_chart_with_configs
    post '/example/a', :chart => {:configs => {"a" => "A"}}.to_json
    assert_equal "A", Config.find("example/a").configs["a"]
  end

  def test_post_to_existing_chart_id_with_config_updates_causes_error_and_does_nothing
    post '/example/a', :chart => {:configs => {"a" => "A"}}.to_json
    post '/example/a', :chart => {:configs => {"a" => "B"}}.to_json
    assert !last_response.ok?
    assert_equal "A", Config.find("example/a").configs["a"]
  end

  def test_post_to_existing_chart_id_with_existing_configs_does_nothing
    post '/example/a', :chart => {:configs => {"a" => "A"}}.to_json
    post '/example/a', :chart => {:configs => {"a" => "A"}}.to_json
    assert_equal "A", Config.find("example/a").configs["a"]
  end

  def test_post_to_existing_chart_id_with_configs_updates_configs_if_force
    post '/example/a', :chart => {:configs => {"a" => "A"}}.to_json
    post '/example/a', :chart => {:configs => {"a" => "B"}}.to_json, :force => "true"
    assert_equal "B", Config.find("example/a").configs["a"]
  end

  ## data

  def test_post_to_chart_id_with_data_saves_data_in_reverse_xz_order
    post '/example/a', :chart => {:data => [
      ["one", 1, 1, 0],
      ["one", 1, 2, 1],
      ["one", 2, 1, 2],
      ["one", 2, 2, 3],
      ["two", 1, 1, 4]
    ]}.to_json

    config = Config.find("example/a")
    assert_equal [
      ["one", 2, 2, 3],
      ["one", 2, 1, 2],
      ["one", 1, 2, 1],
      ["one", 1, 1, 0],
    ], config.find_data("one", 0, 2)

    assert_equal [
      ["two", 1, 1, 4]
    ], config.find_data("two", 0, 2)
  end
end
