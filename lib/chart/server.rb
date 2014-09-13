require 'sinatra/base'
require 'sinatra/contrib'
require 'json'
require 'chart'
require 'chart/topic'

module Chart
  class Server < Sinatra::Base
    PROJECT_ROOT = File.expand_path("../../..", __FILE__)

    register Sinatra::Contrib

    set :app_file, __FILE__
    set :root, PROJECT_ROOT
    set :public_dir, settings.root + "/public"
    set :views, settings.root + "/views"
    set :method_override, true
    set :bind, "0.0.0.0"
    set :port, 4567

    # curl -X POST -F 'config={"x":"X"}' -H "Accept: application/json" http://localhost:4567/chart/two
    # curl -H "Accept: application/json" http://localhost:4567/chart/two

    get('/topics')    { list }
    get('/topics/*')  { show(params[:splat][0]) }
    post('/topics/*') { save(params[:splat][0], params[:topic], params[:force]) }
    get('/data/*')    { data(params[:splat][0], params[:x]) }

    def list
      ids = Topic.list
      respond_to do |f|
        f.html { erb :index, :locals => {:ids => ids } }
        f.json { {"ids" => ids}.to_json }
      end
    end

    def find(id)
      Topic.find(id) || halt(404, "not found: #{id.inspect}")
    end

    def show(id)
      topic = find(id)
      chart = "monitor"
      transport = "data"

      respond_to do |f|
        f.html { erb :"charts/#{chart}.html", :locals => {
          :id => id,
          :chart => chart,
          :transport => transport,
          :topic => topic
        } }
        f.json { topic.to_json }
      end
    end

    def save(id, attrs_json, force)
      attrs = attrs_json ? JSON.parse(attrs_json) : {}
      force = force == "true"

      config = attrs["config"]
      data   = attrs["data"]

      if topic = Topic.find(id)
        case
        when config.nil? || config.empty? || topic.config == config
          # do nothing
        when force
          topic.config = config
          topic.save
        else
          halt 500, "cannot overwrite existing config"
        end
      else
        config ||= Topic.guess_config_for(data)
        topic = Topic.create(id, config)
      end

      if data
        data = topic.deserialize_data(data)
        topic.save_data(data)
      end

      respond_to do |f|
        f.html { redirect "/#{id}" }
        f.json { topic.to_json }
      end
    end

    def data(id, range_str)
      topic = Topic.find(id)
      range = topic.x_type.parse(range_str)
      data  = topic.find_data(*range)
      data  = topic.serialize_data(data)
      respond_to do |f|
        f.html { data.inspect }
        f.json { {'data' => data}.to_json }
      end
    end

    helpers do
      def base_url
        @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
      end

      def fetch_url(id, transport)
        File.join(base_url, id, transport)
      end
    end
  end
end
