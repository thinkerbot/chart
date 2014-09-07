require "chart/version"
require "chart/parsers"
require "chart/receivers"
require "chart/senders"
require "chart/env"

module Chart
  module_function

  def options(overrides = {})
    Env.options(overrides)
  end

  def setup(options = {})
    @connection, @config = Env.setup(options)
  end

  def setup?
    @connection ? true : false
  end

  def reset
    if setup?
      @connection.close
      @connection = nil
      @config = nil
    end
  end

  def conn
    @connection or raise "connection is not setup"
  end

  def config
    @config or raise "config is not setup"
  end

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end
end
