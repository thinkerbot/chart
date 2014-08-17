require "chart/version"
require "chart/parser"
require "chart/feeders"

module Chart
  module_function

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end
end
