require "chart/version"
require "chart/driver"

module Chart
  module_function

  def options(overrides = {})
    Config.options(overrides)
  end

  def setup(options = {})
    @config = Config.create(options)
    @driver = Driver.create(@config)
    self
  end

  def config
    @config
  end

  def driver
    @driver
  end

  def setup?
    @config ? true : false
  end

  def teardown
    driver.teardown if driver
    @driver = nil
    @config = nil
    self
  end

  def version
    "chart version %s (%s)" % [VERSION, RELDATE]
  end

  #
  # API
  #

  def list
    driver.list
  end

  def find(id)
    driver.find(id)
  end

  def create(type, id, config = {})
    driver.create(type, id, config)
  end
end
