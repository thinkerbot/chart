require "chart/version"
require "chart/parsers"
require "chart/receivers"
require "chart/senders"

module Chart
  module_function

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end
end
