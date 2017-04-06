require_relative "base"

# Picks 1 reviewer from a list of reviewers
class ListStrategy < BaseStrategy
  def pick_reviewers(pr_creator: )
    (@reviewer_pool-[pr_creator]).sample(1)
  end
end
