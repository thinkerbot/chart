require File.expand_path('../../helper', __FILE__)

module Chart
  # Tests the API of the Chart::Connection
  module ConnectionTest
    include TopicHelper

    def conn
      raise NotImplementedError
    end

    # Topics

    def test_topic_lifecycle
      assert_equal nil, conn.select_topic_by_id(test_topic_id)

      inputs = [test_topic_id, "II", {}]
      conn.insert_topic(*inputs)

      outputs = conn.select_topic_by_id(test_topic_id)
      assert_equal inputs, outputs
    end

    def test_topic_selection
      a = "#{test_topic_id}/a"
      b = "#{test_topic_id}/b"
      c = "#{test_topic_id}/c"

      ids = [a, b, c]
      assert_equal [], ids & conn.select_topic_ids

      ids.each {|id| conn.insert_topic(id, "II", {}) }
      assert_equal ids, ids & conn.select_topic_ids
    end

    # Data

    def test_data_lifecycle
      id, type = test_topic_id, 'II'

      data_with_pkey = [
        [0, 0, 1],
        [0, 1, 2],
        [1, 2, 3],
        [2, 3, 4],
      ]
      pkeys = data_with_pkey.map {|pkey, x, y| pkey }.uniq
      data  = data_with_pkey.map {|pkey, x, y| [x, y] }
      xmin  = data.map(&:first).sort.first
      xmax  = data.map(&:first).sort.last

      # no data
      assert_equal [], conn.select_data(id, type, pkeys, xmin, xmax, "[]")

      # all data
      data_with_pkey.each {|pkey, x, y| conn.insert_datum(id, type, pkey, x, y) }
      
      assert_equal data, conn.select_data(id, type, pkeys, xmin, xmax, "[]").sort
      assert_equal data, conn.select_data(id, type, pkeys, xmin, xmax + 1, "[)").sort
      assert_equal data, conn.select_data(id, type, pkeys, xmin - 1, xmax, "(]").sort
      assert_equal data, conn.select_data(id, type, pkeys, xmin - 1, xmax + 1, "()").sort

      # subsets by x
      subset = data[1,2]
      assert_equal subset, conn.select_data(id, type, pkeys, 1, 2, "[]").sort
      assert_equal subset, conn.select_data(id, type, pkeys, 1, 3, "[)").sort
      assert_equal subset, conn.select_data(id, type, pkeys, 0, 2, "(]").sort
      assert_equal subset, conn.select_data(id, type, pkeys, 0, 3, "()").sort

      # subset by pkey
      subset = data[2,2]
      assert_equal subset, conn.select_data(id, type, [1,2], xmin, xmax, "[]").sort

      # no data in pkeys
      assert_equal [], conn.select_data(id, type, [3], xmin, xmax, "[]").sort
      assert_equal [], conn.select_data(id, type, [], xmin, xmax, "[]").sort
    end

    def test_insert_datum_async
      id, type = test_topic_id, 'II'
      pkey = 0
      data = [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
      ]
      xmin = data.map(&:first).sort.first
      xmax = data.map(&:first).sort.last

      data.map {|x, y| conn.insert_datum_async(id, type, pkey, x, y) }.map(&:join)
      assert_equal data, conn.select_data(id, type, [pkey], xmin, xmax, "[]").sort
    end
  end
end
