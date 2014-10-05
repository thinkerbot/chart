# coding: utf-8
lib = File.expand_path('../lib', __FILE__)
$LOAD_PATH.unshift(lib) unless $LOAD_PATH.include?(lib)
require 'chart/version'

Gem::Specification.new do |spec|
  spec.name          = "chart"
  spec.version       = Chart::VERSION
  spec.authors       = ["Simon Chiang"]
  spec.email         = ["simon.a.chiang@gmail.com"]
  spec.description   = %q{Make charts from the command line.}
  spec.summary       = %q{Make charts from the command line.}
  spec.homepage      = ""
  spec.license       = "MIT"

  spec.files         = []
  spec.executables   = ["chart-send", "chart-server", "chart-console"]
  spec.test_files    = []
  spec.require_paths = ["lib"]

  spec.add_dependency "sinatra"
  spec.add_dependency "sinatra-contrib"
  spec.add_dependency "cql-rb"
  spec.add_dependency "logging"
  spec.add_dependency "timeseries"
  spec.add_development_dependency "bundler", "~> 1.3"
  spec.add_development_dependency "rake"
end
