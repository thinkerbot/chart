#!/usr/bin/env ruby
require File.expand_path('../../helper', __FILE__)
require 'chart/server'
require 'rack/test'

class Chart::ServerTest < Minitest::Test
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

  def test_post_to_topic_id_creates_topic
    assert_equal nil, Topic.find(test_topic_id)
    post "/topics/#{test_topic_id}"
    assert_equal test_topic_id, Topic.find(test_topic_id).id
  end

  def test_post_to_topic_id_with_config_creates_topic_with_config
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "A"}}
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_to_existing_topic_id_causes_error_and_does_nothing
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "A"}}
    post "/topics/#{test_topic_id}", :topic => {:config => {"a" => "B"}}
    assert !last_response.ok?
    assert_equal "A", Topic.find(test_topic_id).config["a"]
  end

  def test_post_guesses_ii_type_if_unspecified
    post "/topics/#{test_topic_id}"
    assert_equal "ii", Topic.find(test_topic_id).type
  end

  #
  # POST data
  #

  def create_ii_topic
    topic = Topic.create(test_topic_id)
    topic.save_data([
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
    ])
  end

  def reverse_data_from_1_to_2
    [
      [2, 3],
      [1, 2],
    ]
  end

  def test_post_multipart_to_data_saves_data_in_reverse_xz_order
    post "/topics/#{test_topic_id}"
    post "/data/#{test_topic_id}", {
      :data => [
        [0, 1].join(","),
        [1, 2].join(","),
        [2, 3].join(","),
        [3, 4].join(","),
      ].join("\n")
    }

    topic = Topic.find(test_topic_id)
    assert_equal reverse_data_from_1_to_2, topic.find_data(1, 2, "[]")
  end

  def test_post_csv_to_data_saves_data_in_reverse_xz_order
    header "Content-Type", "text/csv"

    post "/topics/#{test_topic_id}"
    post "/data/#{test_topic_id}", [
      [0, 1].join(","),
      [1, 2].join(","),
      [2, 3].join(","),
      [3, 4].join(","),
    ].join("\n")

    topic = Topic.find(test_topic_id)
    assert_equal reverse_data_from_1_to_2, topic.find_data(1, 2, "[]")
  end

  def test_post_json_to_data_saves_data_in_reverse_xz_order
    header "Content-Type", "application/json"

    post "/topics/#{test_topic_id}"
    post "/data/#{test_topic_id}", [
      [0, 1],
      [1, 2],
      [2, 3],
      [3, 4],
    ].to_json

    topic = Topic.find(test_topic_id)
    assert_equal reverse_data_from_1_to_2, topic.find_data(1, 2, "[]")
  end

  #
  # GET data
  #

  def test_get_data_returns_data_in_bucket_in_reverse_xz_order
    create_ii_topic
    header "Accept", "application/json"

    get "/data/#{test_topic_id}?x=1"
    assert_equal [
      [1, 2],
    ], JSON.parse(last_response.body)
  end

  def test_get_data_as_csv
    create_ii_topic
    header "Accept", "text/csv"

    get "/data/#{test_topic_id}?x=1"
    assert_equal [
      ["x", "y"],
      ["1", "2"],
    ], CSV.new(last_response.body).each.to_a
  end

  def test_get_data_without_x_uses_default_range
    create_ii_topic
    header "Accept", "application/json"

    get "/data/#{test_topic_id}"
    assert_equal [
      [3, 4],
      [2, 3],
      [1, 2],
      [0, 1],
    ], JSON.parse(last_response.body)
  end

  def test_get_data_returns_data_in_min_max_range_in_reverse_xz_order
    create_ii_topic
    header "Accept", "application/json"

    get "/data/#{test_topic_id}?x=[1,2]"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=[1,3)"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=(0,2]"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=(0,3)"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)
  end

  def test_get_data_returns_data_in_min_offset_range_in_reverse_xz_order
    create_ii_topic
    header "Accept", "application/json"

    # plus
    get "/data/#{test_topic_id}?x=[1~1]"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=[1~2)"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=(0~2]"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=(0~3)"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    # minus
    get "/data/#{test_topic_id}?x=[2~-1]"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=[3~-2)"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=(2~-2]"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)

    get "/data/#{test_topic_id}?x=(3~-3)"
    assert_equal reverse_data_from_1_to_2, JSON.parse(last_response.body)
  end

  def test_get_data_with_a_projection
    create_ii_topic
    header "Accept", "application/json"

    get "/data/#{test_topic_id}?projection=histogram"
    assert_equal [
      [4,1],
      [3,1],
      [2,1],
      [1,1],
    ], JSON.parse(last_response.body)
  end
end
