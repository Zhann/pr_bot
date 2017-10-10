require_relative '../test_helper'
require_relative '../../lib/strategies/teams_strategy.rb'

describe TeamsStrategy do
  before do
    pool = [{"captains" => ["user1"], "members" => ["user2", "user3"]}, {"captains" => ["user4"], "members" => ["user5", "user6"]}]
    @strategy = TeamsStrategy.new(reviewer_pool: pool)
  end

  describe "for a captain" do
    it "picks 2 members from the same team" do
      reviewers = @strategy.pick_reviewers(pr_creator: "user1")
      assert_equal ["user2", "user3"], reviewers.sort
      reviewers = @strategy.pick_reviewers(pr_creator: "user4")
      assert_equal ["user5", "user6"], reviewers.sort
    end
  end

  describe "for a member" do
    it "picks the captain and another member from the same team" do
      reviewers = @strategy.pick_reviewers(pr_creator: "user2")
      assert_includes reviewers, "user1"
      assert (reviewers.include?("user2") ^ reviewers.include?("user3"))
    end
  end

  describe "works for a non-team member" do
    it "picks one user from the 1st team and one user from the other team" do
      reviewers = @strategy.pick_reviewers(pr_creator: "user7")
      assert_equal 2, reviewers.length
      assert (reviewers.include?("user1") ^ reviewers.include?("user2") ^ reviewers.include?("user3"))
      assert (reviewers.include?("user4") ^ reviewers.include?("user5") ^ reviewers.include?("user6"))
    end
  end

  describe "works without captains" do
    before do
      pool = [{"members" => ["user1", "user2", "user3"], "count" => 2}, {"members" => ["user4", "user5", "user6"], "count" => 1}]
      @strategy = TeamsStrategy.new(reviewer_pool: pool)
    end

    it "picks team member from the same team" do
      reviewers = @strategy.pick_reviewers(pr_creator: "user2")

      assert reviewers.include?("user1")
      assert reviewers.include?("user3")

      reviewers = @strategy.pick_reviewers(pr_creator: "user5")
      assert (reviewers.include?("user4") ^ reviewers.include?("user5") ^ reviewers.include?("user6"))
    end
  end

end
