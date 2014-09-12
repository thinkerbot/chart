#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/server'
require 'rack/test'

class Chart::ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include ModelHelper

  Topic = Chart::Topic

  def setup
    super
    Topic.delete_all
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

  def test_index_lists_topics_by_id
    Topic.create("example/a")
    Topic.create("example/b")

    get '/'
    assert last_response.body.include?("example/a")
    assert last_response.body.include?("example/b")
  end

  #
  # show
  #

  def test_get_existing_topic_returns_ok
    Topic.create("example/a")
    get '/example/a'
    assert last_response.ok?
  end

  def test_get_non_existant_topic_returns_404
    get '/example/a'
    assert_equal 404, last_response.status
  end

  #
  # create/update config
  #

  ## config

  def test_post_to_topic_id_creates_topic
    assert_equal nil, Topic.find("example/a")
    post '/example/a'
    assert_equal "example/a", Topic.find("example/a").id
  end

  def test_post_to_topic_id_with_config_creates_topic_with_config
    post '/example/a', :topic => {:config => {"a" => "A"}}.to_json
    assert_equal "A", Topic.find("example/a").config["a"]
  end

  def test_post_to_existing_topic_id_with_config_updates_causes_error_and_does_nothing
    post '/example/a', :topic => {:config => {"a" => "A"}}.to_json
    post '/example/a', :topic => {:config => {"a" => "B"}}.to_json
    assert !last_response.ok?
    assert_equal "A", Topic.find("example/a").config["a"]
  end

  def test_post_to_existing_topic_id_with_existing_config_does_nothing
    post '/example/a', :topic => {:config => {"a" => "A"}}.to_json
    post '/example/a', :topic => {:config => {"a" => "A"}}.to_json
    assert_equal "A", Topic.find("example/a").config["a"]
  end

  def test_post_to_existing_topic_id_with_config_updates_config_if_force
    post '/example/a', :topic => {:config => {"a" => "A"}}.to_json
    post '/example/a', :topic => {:config => {"a" => "B"}}.to_json, :force => "true"
    assert_equal "B", Topic.find("example/a").config["a"]
  end

  ## data

  def test_post_to_topic_id_with_data_saves_data_in_reverse_xz_order
    post '/example/a', :topic => {:data => [
      [1, 1, 0],
      [1, 2, 1],
      [2, 1, 2],
      [2, 2, 3],
    ]}.to_json

    topic = Topic.find("example/a")
    assert_equal [
      [2, 2, 3],
      [2, 1, 2],
      [1, 2, 1],
      [1, 1, 0],
    ], topic.find_data(0, 2)
  end

  def test_get_data_returns_data_in_range_in_reverse_xz_order
    topic = Topic.create("example/a")
    topic.save_data([
      [1, 1, 0],
      [1, 2, 1],
      [2, 1, 2],
      [2, 2, 3],
    ])

    get '/example/a/data?&xmin=0&xmax=2'
    json = JSON.parse(last_response.body)
    assert_equal [
      [2, 2, 3],
      [2, 1, 2],
      [1, 2, 1],
      [1, 1, 0],
    ], json
  end
end
