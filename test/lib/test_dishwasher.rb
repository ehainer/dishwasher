require 'test_helper'
class TestDishwasher < Minitest::Test
  def setup
    @load = Dishwasher::Load.new
  end

  def test_has_recent_load?
    
    Dishwasher::Load.all.count > 0
  end
end