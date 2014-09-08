require 'sinatra/base'
require 'sinatra/contrib'
require 'json'
require 'chart'
require 'chart/config'

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

    get('/')   { list }
    get('/*')  { show(params[:splat][0]) }
    post('/*') { puts params.inspect; save(params[:splat][0], params[:config]) }

    def list
      ids = Config.list(settings.conn)
      respond_to do |f|
        f.html { erb :index, :locals => {:ids => ids } }
        f.json { ids }
      end
    end

    def show(id)
      config = Config.find(id, settings.conn)
      chart = "monitor"
      transport = "data"

      respond_to do |f|
        f.html { erb :"charts/#{chart}.html", :locals => {
          :id => id,
          :chart => chart,
          :transport => transport,
          :config => config
        } }
        f.json { config.to_json }
      end
    end

    def save(id, configs_json)
      if configs_json
        config = Config.from_values([id, configs_json])
        config.save(settings.conn)
      else
        config = Config.find(id)
      end

      respond_to do |f|
        f.html { redirect "/#{id}" }
        f.json { config.to_json }
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
