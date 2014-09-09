require "chart/version"
require "chart/model"

module Chart
  module_function

  def options(overrides = {})
    Connection.options(overrides)
  end

  def setup(options = {})
    Model.connect(options)
    self
  end

  def setup?
    Model.connected?
  end

  def reset
    Model.disconnect
  end

  def conn
    Model.connection
  end

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end
end
