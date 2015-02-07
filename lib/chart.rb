require "chart/version"
require "chart/context"

module Chart
  module_function

  def options(overrides = {})
    Context.options(overrides)
  end

  def setup(options = {})
    @context = Context.create(options)
    self
  end

  def context
    @context or raise("no context has been set")
  end

  def setup?
    context ? true : false
  end

  def reset
    context.reset if context
    @context = nil
    self
  end

  def conn
    context.connection
  end

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end
end
