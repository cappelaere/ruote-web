
require File.dirname(__FILE__) + '/../test_helper'

class WiStoreTest < Test::Unit::TestCase

  fixtures :wi_stores, :store_permissions, :users

  def test_find_store_names

    wl = Worklist.new(users(:alice))

    assert_equal wl.store_names, [ "alpha", "bravo", "users" ]
  end

  def test_alice

    wl = Worklist.new(users(:alice))

    assert wl.permission("alpha").may_read?
  end

  def test_bob

    wl = Worklist.new(users(:bob))

    assert wl.permission("alpha").may_read?
    assert ( ! wl.permission("alpha").may_write?)
  end
end
