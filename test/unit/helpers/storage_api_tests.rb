require File.expand_path('../../helpers/storage_helper', __FILE__)

module Chart
  module StorageAPITests
    include StorageHelper

    # Topics

    def test_topic_lifecycle
      assert_equal nil, storage.select_topic_by_id(test_id)

      inputs = ["II", test_id, {}]
      storage.insert_topic(*inputs)

      outputs = storage.select_topic_by_id(test_id)
      assert_equal inputs, outputs
    end

    def test_topic_selection
      a = "#{test_id}/a"
      b = "#{test_id}/b"
      c = "#{test_id}/c"

      ids = [a, b, c]
      assert_equal [], ids & storage.select_topic_ids

      ids.each {|id| storage.insert_topic("II", id, {}) }
      assert_equal ids, ids & storage.select_topic_ids
    end

    # Data

    def test_data_lifecycle
      type, id = 'II', test_id

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
      assert_equal [], storage.select_data(type, id, pkeys, xmin, xmax, "[]")

      # all data
      data_with_pkey.each {|pkey, x, y| storage.insert_datum(type, id, pkey, x, y) }
      
      assert_equal data, storage.select_data(type, id, pkeys, xmin, xmax, "[]").sort
      assert_equal data, storage.select_data(type, id, pkeys, xmin, xmax + 1, "[)").sort
      assert_equal data, storage.select_data(type, id, pkeys, xmin - 1, xmax, "(]").sort
      assert_equal data, storage.select_data(type, id, pkeys, xmin - 1, xmax + 1, "()").sort

      # subsets by x
      subset = data[1,2]
      assert_equal subset, storage.select_data(type, id, pkeys, 1, 2, "[]").sort
      assert_equal subset, storage.select_data(type, id, pkeys, 1, 3, "[)").sort
      assert_equal subset, storage.select_data(type, id, pkeys, 0, 2, "(]").sort
      assert_equal subset, storage.select_data(type, id, pkeys, 0, 3, "()").sort

      # subset by pkey
      subset = data[2,2]
      assert_equal subset, storage.select_data(type, id, [1,2], xmin, xmax, "[]").sort

      # no data in pkeys
      assert_equal [], storage.select_data(type, id, [3], xmin, xmax, "[]").sort
      assert_equal [], storage.select_data(type, id, [], xmin, xmax, "[]").sort
    end

    def test_insert_datum_async
      type, id = 'II', test_id
      pkey = 0
      data = [
        [0, 1],
        [1, 2],
        [2, 3],
        [3, 4],
      ]
      xmin = data.map(&:first).sort.first
      xmax = data.map(&:first).sort.last

      futures = data.map {|x, y| storage.insert_datum_async(type, id, pkey, x, y) }
      assert_equal true, futures.all? {|f| f.respond_to?(:join) }
      
      futures.each(&:join)
      assert_equal data, storage.select_data(type, id, [pkey], xmin, xmax, "[]").sort
    end
  end
end
