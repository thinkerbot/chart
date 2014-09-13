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

  ## data

  def create_iii_topic
    topic = Topic.create(test_topic_id)
    topic.save_data([
      [0, 1, 0],
      [0, 2, 1],
      [1, 1, 2],
      [1, 2, 3],
      [2, 1, 4],
      [2, 2, 5],
      [3, 1, 6],
      [3, 2, 7],
    ])
  end

  def reverse_data_from_1_to_2
    [
      [2, 2, 5],
      [2, 1, 4],
      [1, 2, 3],
      [1, 1, 2],
    ]
  end

  def test_post_to_topic_id_with_data_saves_data_in_reverse_xz_order
    post "/topics/#{test_topic_id}", :topic => {:data => [
      [0, 1, 0],
      [0, 2, 1],
      [1, 1, 2],
      [1, 2, 3],
      [2, 1, 4],
      [2, 2, 5],
      [3, 1, 6],
      [3, 2, 7],
    ]}.to_json

    topic = Topic.find(test_topic_id)
    assert_equal reverse_data_from_1_to_2, topic.find_data(1, 2, "[]")
  end

  def test_get_data_returns_data_in_bucket_in_reverse_xz_order
    create_iii_topic
    header "Accept", "application/json"

    get "/data/#{test_topic_id}?x=1"
    assert_equal [
      [1, 2, 3],
      [1, 1, 2],
    ], parse_data(last_response.body)
  end

  def test_get_data_returns_data_in_min_max_range_in_reverse_xz_order
    create_iii_topic
    header "Accept", "application/json"

    get "/data/#{test_topic_id}?x=[1,2]"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=[1,3)"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=(0,2]"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=(0,3)"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)
  end

  def test_get_data_returns_data_in_min_offset_range_in_reverse_xz_order
    create_iii_topic
    header "Accept", "application/json"

    # plus
    get "/data/#{test_topic_id}?x=[1:1]"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=[1:2)"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=(0:2]"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=(0:3)"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    # minus
    get "/data/#{test_topic_id}?x=[2:-1]"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=[3:-2)"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=(2:-2]"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)

    get "/data/#{test_topic_id}?x=(3:-3)"
    assert_equal reverse_data_from_1_to_2, parse_data(last_response.body)
  end

  ### data types

  def test_post_iii_data
    header "Accept", "application/json"

    post "/topics/#{test_topic_id}", :topic => {
      :config => {:dimensions => ["i", "i", "i"]},
      :data => [[0, 1, -2]]
    }.to_json

    get "/data/#{test_topic_id}?x=0"
    assert_equal [[0, 1, -2]], parse_data(last_response.body)
  end

  def test_post_ddd_data
    header "Accept", "application/json"

    post "/topics/#{test_topic_id}", :topic => {
      :config => {:dimensions => ["d", "d", "d"]},
      :data => [[0.0, 1.1, -2.2]]
    }.to_json

    get "/data/#{test_topic_id}?x=0.0"
    assert_equal [[0.0, 1.1, -2.2]], parse_data(last_response.body)
  end

  def test_post_tit_data
    header "Accept", "application/json"

    post "/topics/#{test_topic_id}", :topic => {
      :config => {:dimensions => ["t", "i", "t"]},
      :data => [["2010-01-01T00:00:00Z", 1, "2011-01-01T00:00:00Z"]]
    }.to_json

    get "/data/#{test_topic_id}?x=2010-01-01T00:00:00Z"
    assert_equal [["2010-01-01T00:00:00Z", 1, "2011-01-01T00:00:00Z"]], parse_data(last_response.body)
  end

  def test_post_tdt_data
    header "Accept", "application/json"

    post "/topics/#{test_topic_id}", :topic => {
      :config => {:dimensions => ["t", "d", "t"]},
      :data => [["2010-01-01T00:00:00Z", 1.1, "2011-01-01T00:00:00Z"]]
    }.to_json

    get "/data/#{test_topic_id}?x=2010-01-01T00:00:00Z"
    assert_equal [["2010-01-01T00:00:00Z", 1.1, "2011-01-01T00:00:00Z"]], parse_data(last_response.body)
  end

  def test_post_tst_data
    header "Accept", "application/json"

    post "/topics/#{test_topic_id}", :topic => {
      :config => {:dimensions => ["t", "s", "t"]},
      :data => [["2010-01-01T00:00:00Z", "true", "2011-01-01T00:00:00Z"]]
    }.to_json

    get "/data/#{test_topic_id}?x=2010-01-01T00:00:00Z"
    assert_equal [["2010-01-01T00:00:00Z", "true", "2011-01-01T00:00:00Z"]], parse_data(last_response.body)
  end
end
