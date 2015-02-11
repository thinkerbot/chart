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

  #
  # table_name_for
  #

  def test_table_name_for_returns_table_name_derived_from_type
    assert_equal "ii_data", CassandraStorage.table_name_for("ii")
  end

  #
  # column_names_for
  #

  def test_column_names_for_returns_array_of_column_names_derived_from_type
    assert_equal ["x", "y"], CassandraStorage.column_names_for("ii")
  end
end
