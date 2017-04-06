require_relative 'base'

# Split your app into teams, this strategy figures out which team
# the creator is from and assigns the captain and anthor team member
class TeamsStrategy < BaseStrategy
  def pick_reviewers(pr_creator: )
    if captain?(pr_creator)
      team_for(pr_creator)["members"].sample(2)
    elsif member?(pr_creator)
      team = team_for(pr_creator)
      [Array(team["captains"]).sample(1), (team["members"] - [pr_creator]).sample(1)].flatten
    else
      @reviewer_pool.sample(2).map { |team| all_for_team(team).sample(1) }.flatten
    end
  end

  private
  def team_for(user)
    @reviewer_pool.detect do |team|
      if captain?(user)
        Array(team["captains"]).include?(user)
      elsif member?(user)
        Array(team["members"]).include?(user)
      end
    end
  end

  def captain?(user)
    @reviewer_pool.map { |team| team["captains"] }.flatten.include?(user)
  end

  def member?(user)
    @reviewer_pool.map { |team| team["members"] }.flatten.include?(user)
  end

  def all_for_team(team)
    team["members"] + Array(team["captains"])
  end
end
