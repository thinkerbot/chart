require 'sinatra/base'
require 'sinatra/contrib'
require 'json'
require 'csv'
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

    # curl -X POST -d '{"x":"X"}' -H "Content-Type: application/json" http://localhost:4567/
    # curl -X POST -F 'config={"x":"X"}' -H "Accept: application/json" http://localhost:4567/chart/two
    # curl -H "Accept: application/json" http://localhost:4567/chart/two

    get('/')          { redirect '/topics' }
    get('/topics')    { list }
    get('/topics/*')  { show(params[:splat][0]) }
    post('/topics/*') { create(params[:splat][0], params[:topic] || {}) }

    get('/data/*')    { read_data(params[:splat][0], params[:x]) }
    post('/data/*')   { write_data(params[:splat][0], parse_data) }

    def parse_data
      case request.content_type
      when "application/json"
        JSON.load(request.body)
      when "text/csv"
        CSV.new(request.body)
      when "multipart/form-data", "application/x-www-form-urlencoded"
        csv = params["data"]
        CSV.parse(csv)
      else
        halt(422, "unsupported content-type: #{request.content_type.inspect}")
      end
    end

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
      respond_to do |f|
        f.html { erb :show, :locals => {
          :id => id,
          :topic => topic
        } }
        f.json { topic.to_json }
      end
    end

    def create(id, attrs)
      type   = attrs.fetch("type", 'ii')
      config = attrs.fetch("config", {})

      if existing_topic = Topic.find(id)
        halt(422, "already exists: #{id.inspect}")
      end

      topic  = Topic.create(id, type, config)
      respond_to do |f|
        f.html { redirect "/#{id}" }
        f.json { topic.to_json }
      end
    end

    def write_data(id, data)
      topic = find(id)
      topic.write_data(data)

      respond_to do |f|
        f.html { redirect "/#{id}" }
        f.json { {:received => data.length}.to_json }
      end
    end

    def read_data(id, range_str)
      topic = find(id)
      data  = topic.read_data(range_str)

      respond_to do |f|
        f.html { data.inspect }
        f.json { data.to_json }
        f.csv  { CSV.generate {|csv| data.each {|d| csv << d }} }
      end
    end

    helpers do
      def base_url
        @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
      end
    end
  end
end
