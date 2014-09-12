#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/server'
require 'rack/test'

class Chart::ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods
  include TopicHelper

  Topic = Chart::Topic

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
    Topic.create(test_topic_id("a"))
    Topic.create(test_topic_id("b"))

    get '/'
    assert last_response.body.include?(test_topic_id("a"))
    assert last_response.body.include?(test_topic_id("b"))
  end

  #
  # show
  #

  def test_get_existing_topic_returns_ok
    Topic.create(test_topic_id)
    get "/#{test_topic_id}"
    assert last_response.ok?
  end

  def test_get_non_existant_topic_returns_404
    get "/#{test_topic_id}"
    assert_equal 404, last_response.status
  end

  #
  # create/update config
  #

  ## config

  def test_post_to_topic_id_creates_topic
    assert_equal nil, Topic.find(test_topic_id)
    post "/#{test_topic_id}"
    assert_equal test_topic_id, Topic.find(test_topic_id).id
  end

  def test_post_to_topic_id_with_config_creates_topic_with_config
    post "/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_to_existing_topic_id_with_config_updates_causes_error_and_does_nothing
    post "/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    post "/#{test_topic_id}", :topic => {:config => {"a" => "B"}}.to_json
    assert !last_response.ok?
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_to_existing_topic_id_with_existing_config_does_nothing
    post "/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    post "/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_to_existing_topic_id_with_config_updates_config_if_force
    post "/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    post "/#{test_topic_id}", :topic => {:config => {"a" => "B"}}.to_json, :force => "true"
    assert_equal "B", Topic.find(test_topic_id).config["a"]
  end

  ## data

  def test_post_to_topic_id_with_data_saves_data_in_reverse_xz_order
    post "/#{test_topic_id}", :topic => {:data => [
      [1, 1, 0],
      [1, 2, 1],
      [2, 1, 2],
      [2, 2, 3],
    ]}.to_json

    topic = Topic.find(test_topic_id)
    assert_equal [
      [2, 2, 3],
      [2, 1, 2],
      [1, 2, 1],
      [1, 1, 0],
    ], topic.find_data(0, 2)
  end

  def test_get_data_returns_data_in_range_in_reverse_xz_order
    topic = Topic.create(test_topic_id)
    topic.save_data([
      [1, 1, 0],
      [1, 2, 1],
      [2, 1, 2],
      [2, 2, 3],
    ])

    get "/#{test_topic_id}/data?&xmin=0&xmax=2"
    json = JSON.parse(last_response.body)
    assert_equal [
      [2, 2, 3],
      [2, 1, 2],
      [1, 2, 1],
      [1, 1, 0],
    ], json
  end
end
