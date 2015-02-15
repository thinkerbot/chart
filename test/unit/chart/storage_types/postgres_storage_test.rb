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

  def setup
    storage.execute("truncate table ii_data;")
  end

  #
  # table_name_for
  #

  def test_table_name_for_returns_table_name_derived_from_type
    assert_equal "ii_data", PostgresStorage.table_name_for("ii")
  end

  #
  # column_names_for
  #

  def test_column_names_for_returns_array_of_column_names_derived_from_type
    assert_equal ["x", "y"], PostgresStorage.column_names_for("ii")
  end
end
