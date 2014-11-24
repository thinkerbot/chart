#!/usr/bin/env ruby
require File.expand_path('../../../helper', __FILE__)
require 'chart/connections/cassandra_connection'

class Chart::Connections::CassandraConnectionTest < Test::Unit::TestCase
  CassandraConnection = Chart::Connections::CassandraConnection

  #
  # table_name_for
  #

  def test_table_name_for_returns_table_name_derived_from_type
    assert_equal "ii_data", CassandraConnection.table_name_for("ii")
  end

  #
  # column_names_for
  #

  def test_column_names_for_returns_array_of_column_names_derived_from_type
    assert_equal ["x", "y"], CassandraConnection.column_names_for("ii")
  end
end
