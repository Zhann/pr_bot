require_relative '../test_helper'
require_relative '../../lib/strategies/tiered_strategy.rb'

describe TieredStrategy do
  it "picks the right reviewers" do
    pool = [{"count" => 1, "names" => ["user1","user2"]},{"count" => 2, "names" => ["user3","user4","user5"]}]
    @strategy = TieredStrategy.new(reviewer_pool: pool)
    reviewers = @strategy.pick_reviewers(pr_creator: "user2")
    assert_includes reviewers, "user1"
    assert !reviewers.include?("user2")
    assert (!reviewers.include?("user3") ^ !reviewers.include?("user4") ^ !reviewers.include?("user5"))
  end
end
