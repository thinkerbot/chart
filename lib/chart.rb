require "chart/version"
require "chart/context"
require "chart/topics"

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

  def teardown
    context.teardown if context
    @context = nil
    self
  end

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end

  #
  # API
  #

  def list
    context.list
  end

  def find(id)
    context.find(id)
  end

  def create(type, id, config = {})
    context.create(type, id, config)
  end
end
