require "chart/version"

module Chart
  module_function

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end
end
