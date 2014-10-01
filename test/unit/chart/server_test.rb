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

  def parse_data(str)
    JSON.parse(str)['data']
  end

  #
  # list
  #

  def test_index_responds_ok
    get '/topics'
    assert last_response.ok?
  end

  def test_index_lists_topics_by_id
    Topic.create(test_topic_id("a"))
    Topic.create(test_topic_id("b"))

    get '/topics'
    assert last_response.body.include?(test_topic_id("a"))
    assert last_response.body.include?(test_topic_id("b"))
  end

  #
  # show
  #

  def test_get_existing_topic_returns_ok
    Topic.create(test_topic_id)
    get "/topics/#{test_topic_id}"
    assert last_response.ok?
  end

  def test_get_non_existant_topic_returns_404
    get "/topics/#{test_topic_id}"
    assert_equal 404, last_response.status
  end

  #
  # create/update config
  #

  ## config

  def test_post_to_topic_id_creates_topic
    assert_equal nil, Topic.find(test_topic_id)
    post "/topics/#{test_topic_id}"
    assert_equal test_topic_id, Topic.find(test_topic_id).id
  end

  def test_post_to_topic_id_with_config_creates_topic_with_config
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_to_existing_topic_id_with_config_updates_causes_error_and_does_nothing
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "B"}}.to_json
    assert !last_response.ok?
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_to_existing_topic_id_with_existing_config_does_nothing
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_to_existing_topic_id_with_config_updates_config_if_force
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "A"}}.to_json
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "B"}}.to_json, :force => "true"
    assert_equal "B", Topic.find(test_topic_id).config["a"]
  end
end
