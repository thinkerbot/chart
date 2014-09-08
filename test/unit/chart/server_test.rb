require File.expand_path('../../helper', __FILE__)
require 'chart/server'
require 'rack/test'

class Chart::ServerTest < Test::Unit::TestCase
  include Rack::Test::Methods

  def app
    Chart::Server
  end

  def test_index_responds_ok
    get '/'
    assert last_response.ok?
  end
end
