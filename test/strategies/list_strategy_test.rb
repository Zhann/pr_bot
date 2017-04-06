require_relative '../test_helper'
require_relative '../../lib/strategies/list_strategy.rb'

describe ListStrategy do
  it "returns the other name when only 2 in the pool" do
    @strategy = ListStrategy.new(reviewer_pool: ["jack", "jeff"])
    assert_equal ["jeff"], @strategy.pick_reviewers(pr_creator: "jack")
  end
end
