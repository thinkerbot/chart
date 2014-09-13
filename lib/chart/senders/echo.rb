require 'chart/sender'
require 'json'

module Chart
  module Senders
    class Echo < Sender
      def call(datasets)
        datasets.each do |topic, data|
          # post topic with configs and data -- blows up if configs are different and not force
          format = url ? "#{File.join(url, topic)} %s %s %s" : "#{topic} %s %s %s"
          data.each {|xyz| puts format % xyz }
        end
      end
    end
  end
end
