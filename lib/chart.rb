require "chart/version"
require "chart/topic"

module Chart
  module_function

  def options(overrides = {})
    Connection.options(overrides)
  end

  def setup(options = {})
    Topic.connect(options)
    self
  end

  def setup?
    Topic.connected?
  end

  def reset
    Topic.disconnect
  end

  def conn
    Topic.connection
  end

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end
end
