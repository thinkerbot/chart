require 'chart/storage'

module StorageHelper
  SHARED_STORAGE = Hash.new do |hash, type|
    config_file = File.expand_path("../../../../config/test/#{type}", __FILE__)
    config      = Chart::Config.create(
      :config_path => nil,
      :config_file => config_file,
      :settings    => [],
    )
    storage_class = Chart::Storage.lookup(type)
    storage = storage_class.create(config)
    at_exit { storage.close }
    hash[type] = storage
  end

  TEST_RUN_TIME = Time.now.strftime("%Y%m%d%H%M%S")

  def test_id(*suffix)
    File.join(TEST_RUN_TIME, name, *suffix)
  end

  def storage_type
    raise NotImplementedError
  end

  def storage
    SHARED_STORAGE[storage_type]
  end

  def execute(*args)
    storage.execute(*args)
  end
end
