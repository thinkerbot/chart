#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require File.expand_path('../../../helpers/storage_api_tests', __FILE__)
require 'chart/storage_types/cassandra_storage'

class Chart::StorageTypes::CassandraStorageTest < Minitest::Test
  CassandraStorage = Chart::StorageTypes::CassandraStorage
  include Chart::StorageAPITests

  def storage_type
    'cassandra'
  end
end
