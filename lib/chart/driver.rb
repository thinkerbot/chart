require 'chart/storage_types'
require 'chart/topics'
require 'chart/config'

module Chart
  class Driver
    class << self
      def create(config)
        configs = config.section('storage')
        type    = configs['type']

        storage_class = StorageTypes.lookup(type)
        storage       = storage_class.create(config)

        new(storage)
      end
    end
    Config.register_section('storage', {'type' => 'cassandra'})

    attr_reader :storage

    def initialize(storage)
      @storage = storage
    end

    def teardown
      @storage.close
      self
    end

    def list
      storage.select_topic_ids
    end

    def find(id)
      return nil if id.nil?

      type, id, config = storage.select_topic_by_id(id)
      if type
        topic_class = Topics.lookup(type)
        topic_class.new(storage, id, config)
      else
        nil
      end
    end

    def create(type, id, config = {})
      topic_class = Topics.lookup(type)
      topic_class.new(storage, id, config).save
    end
  end
end
