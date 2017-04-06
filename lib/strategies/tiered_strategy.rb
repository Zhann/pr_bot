require_relative "base"

# Reviewer pool defines multiple tiers, this strategy will
# pick `tier.count` reviewers per tier
class TieredStrategy < BaseStrategy
  def pick_reviewers(pr_creator: )
    @reviewer_pool.map do |pool|
      (pool["names"]-[pr_creator]).sample(pool["count"])
    end.flatten
  end
end
