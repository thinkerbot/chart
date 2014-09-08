require 'sinatra/base'
require 'sinatra/contrib'
require 'json'
require 'chart'

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

    get('/') { "ok" }

    helpers do
    end
  end
end
