require 'sinatra/base'
require 'sinatra/contrib'
require 'json'

module Chart
  class Server < Sinatra::Base
    PROJECT_ROOT = File.expand_path("../../..", __FILE__)

    register Sinatra::Contrib

    set :app_file, __FILE__
    set :root, PROJECT_ROOT
    set :public_dir, settings.root + "/public"
    set :views, settings.root + "/views"
    set :storage_dir, settings.root + "/storage"
    set :method_override, true
    set :bind, "0.0.0.0"
    set :port, 4567

    # curl -X POST -F "config[type]=series" -H "Accept: application/json" http://localhost:4567/new
    # curl -H "Accept: application/json" http://localhost:4567/12
    # printf "abc" | curl -X POST -H "Accept: application/json" -F data=@- http://localhost:4567/12/data
    # curl -H "Accept: application/json" http://localhost:4567/12/data

    get('/')          { list }
    post('/new')      { create(params[:config] || {}) }
    get('/:id')       {|id| show(id, params[:transport] || "data") }
    get('/:id/data')  {|id| data(id) }
    post('/:id/data') {|id| write_data(id, params[:data]) }

    def list
      ids = chart_ids
      respond_to do |f|
        f.html { erb :index, :locals => {:ids => ids } }
        f.json { ids }
      end
    end

    def create(config = {})
      begin
        next_id  = (chart_ids.map(&:to_i).max || 0) + 1
        next_dir = chart_dir(next_id)
        next_config_file = config_file(next_id)

        FileUtils.mkdir_p(next_dir)
        File.open(next_config_file, File::CREAT | File::EXCL | File::WRONLY) do |io|
          io << config.to_json
        end

        respond_to do |f|
          f.html { redirect "/#{next_id}" }
          f.json { attrs(next_id).to_json }
        end

      rescue Errno::EEXIST
        # if the config file exists then this error will be raised, meaning
        # someone snuck in the next_id in parallel.  try again!
        create(config)
      end
    end

    def attributes(id)
      file = config_file(id)
      unless File.exists?(file)
        halt(404, "Not Found")
      end

      contents = File.read(file)
      config   = contents.empty? ? {} : JSON.load(contents)
      {'id' => id}.merge(config)
    end

    def show(id, transport)
      attrs = attributes(id)
      chart = params["type"] || attrs["type"] || "monitor"

      respond_to do |f|
        f.html { erb :"charts/#{chart}.html", :locals => {
          :id => id,
          :chart => chart,
          :transport => transport,
          :attrs => attrs(id)
        } }
        f.json { attrs.to_json }
      end
    end

    def read_data(id)
      file = data_file(id)
      File.exists?(file) ? File.readlines(file) : ""
    end

    def data(id)
      respond_to do |f|
        f.html { redirect "/#{id}?transport=data" }
        f.json { {
          :data => read_data(id),
          :headers => [],
        }.to_json }
      end
    end

    def write_data(id, data)
      tempfile = data[:tempfile]

      num_bytes = 0
      File.open(data_file(id), "a") do |io|
        last_line = nil

        while line = tempfile.gets
          io << line
          num_bytes += line.length
          last_line = line
        end

        if last_line && last_line[-1] != ?\n
          io << "\n"
        end
      end

      respond_to do |f|
        f.html { redirect "/#{next_id}/data" }
        f.json { {:num_bytes => num_bytes}.to_json }
      end
    end

    ############################

    helpers do
      def chart_ids
        Dir.glob(chart_path("*")).map {|file| File.basename(file) }
      end

      def chart_path(id, *paths)
        File.join(settings.storage_dir, id.to_s, *paths)
      end

      def chart_dir(id)
        chart_path(id)
      end

      def data_file(id)
        chart_path(id, "data.txt")
      end

      def config_file(id)
        chart_path(id, "config.json")
      end

      def base_url
        @base_url ||= "#{request.env['rack.url_scheme']}://#{request.env['HTTP_HOST']}"
      end

      def fetch_url(id, transport)
        File.join(base_url, id, transport)
      end
    end
  end
end
