ENV['RACK_ENV'] = 'test'

require 'rubygems'
require 'bundler'
Bundler.setup

require 'test/unit'

require 'chart'
unless Chart.setup?
  Chart.setup(:environment => ENV['RACK_ENV'])
end
