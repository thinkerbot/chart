require 'chart/topics/ii_topic'
require 'chart/topics/iii_topic'

module Chart
  module Topics
    module_function

    def lookup(type)
      case type
      when IITopic.type
        IITopic
      when IIITopic.type
        IIITopic
      else
        raise "unknown topic type: #{type}"
      end
    end
  end
end
