#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require File.expand_path('../../../helpers/storage_api_tests', __FILE__)
require 'chart/storage_types/postgres_storage'

class Chart::StorageTypes::PostgresStorageTest < Minitest::Test
  PostgresStorage = Chart::StorageTypes::PostgresStorage
  include Chart::StorageAPITests

  def storage_type
    'postgres'
  end
end
