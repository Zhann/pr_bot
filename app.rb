require 'bundler'
require 'json'
Bundler.require
Dotenv.load

require_relative "lib/strategies/list_strategy.rb"
require_relative "lib/strategies/teams_strategy.rb"
require_relative "lib/strategies/tiered_strategy.rb"

set :bind, ENV['BIND'] || 'localhost'

# Required ENV vars:
#
# GITLAB_TOKEN: S0meToken
# GITLAB_ENDPOINT: https://your.gitlab.com/api/v4
# REVIEWER_POOL (simple strategy): ["user1", "user2", "user3"]
# REVIEWER_POOL (tiered strategy): [{"count": 2, "name": ["andruby","jeff","ron"]},{"count": 1, "names": ["defunkt","pjhyett"]}]
# REVIEWER_POOL (teams strategy): [{"captain": "user1", "members": ["user2", "user3"]},{"captain": "user4", "members": ["user4", "user5"]}]
# PR_LABEL: for-review
#
# Optional ENV vars:
#
# STRATEGY: list OR tiered OR teams (defaults to simple)

class PullRequest
  attr_reader :strategy

  def initialize(payload, reviewer_pool:, label:, strategy: )
    @payload = payload
    @label = label
    @strategy = Object.const_get("#{(strategy || "list").capitalize}Strategy").new(reviewer_pool: reviewer_pool)
  end

  def needs_assigning?
    # Already has an assignee
    return false if @payload["assignee"]

    # When adding label "for-review"
    label_changes = @payload.dig("changes", "labels")

    # No labels where changed
    return false unless label_changes

    # For gitlab, we don't check if someone was already
    return false if label_changes["previous"].detect { |label| label["title"] == @label }
    return true if label_changes["current"].detect { |label| label["title"] == @label }
  end

  def set_assigner!
    assignee_id = username_to_id(reviewer)
    client.update_merge_request(project_id, merge_request_id, assignee_id: assignee_id)
  # rescue Octokit::UnprocessableEntity => e
    # puts "Unable to add set reviewers: #{e.message}"
  end

  def add_comment!
    client.create_merge_request_note(project_id, merge_request_id, message)
  end

  def reviewer
    @reviewer ||= strategy.pick_reviewers(pr_creator: creator).first
  end

  def creator
    @creator ||= begin
      author_id = @payload.dig("object_attributes", "author_id")
      client.user(author_id).username
    end
  end

  private

  def message
    "Thank you @#{creator} for your contribution! I have determined that @#{reviewer} shall review your code"
  end

  def project_id
    @payload.dig("project", "id")
  end

  def merge_request_id
    # URL's need the "internal" id
    @payload.dig("object_attributes", "iid")
  end

  def client
    @@client ||= Gitlab.client(endpoint: ENV['GITLAB_ENDPOINT'], private_token: ENV['GITLAB_TOKEN'])
  end

  def username_to_id(username)
    # puts "Unable to add set reviewers: #{e.message}"
    client.users(username: username).first&.id
  end
end

get '/status' do
  "ok"
end

post '/gitlab-mr' do
  payload = JSON.parse(request.body.read)

  # Write to STDOUT for debugging perpose
  puts "Incoming payload: #{payload.inspect}"

  pull_request = PullRequest.new(payload, reviewer_pool: JSON.parse(ENV['REVIEWER_POOL']), label: ENV['PR_LABEL'], strategy: ENV['STRATEGY'])
  if pull_request.needs_assigning?
    puts "Assigning #{pull_request.reviewer.inspect} to PR from #{pull_request.creator}"
    pull_request.add_comment!
    pull_request.set_assigner!
  else
    puts "No need to assign reviewers"
  end
end
