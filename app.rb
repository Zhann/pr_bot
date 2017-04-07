require 'bundler'
require 'json'
Bundler.require
Dotenv.load

Dir["lib/strategies/*.rb"].each { |f| require_relative(f) }

set :bind, ENV['BIND'] || 'localhost'

# Required ENV vars:
#
# GITHUB_USER: botsname
# GITHUB_PASSWORD: YourPwd
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
    # When adding label "for-review" and no reviewers yet
    @payload["action"] == "labeled" && @payload.dig("label", "name") == @label && gh_client.pull_request_review_requests(repo_id, pr_number) == []
  end

  def set_reviewers!
    gh_client.request_pull_request_review(repo_id, pr_number, reviewers)
  rescue Octokit::UnprocessableEntity => e
    puts "Unable to add set reviewers: #{e.message}"
  end

  def add_comment!
    gh_client.add_comment(repo_id, pr_number, message)
  end

  def reviewers
    @reviewers ||= strategy.pick_reviewers(creator)
  end

  def creator
    @payload.dig("pull_request", "user", "login")
  end

  private

  def message
    reviewers_s = reviewers.map { |a| "@#{a}" }.join(" and ")
    "Thank you @#{creator} for your contribution! I have determined that #{reviewers_s} shall review your code"
  end

  def pr_number
    @payload.dig("number")
  end

  def repo_id
    @payload.dig("repository", "id")
  end

  def gh_client
    @@gh_client ||= Octokit::Client.new(gh_authentication)
  end

  def gh_authentication
    if ENV['GITHUB_TOKEN']
      {access_token: ENV['GITHUB_TOKEN']}
    else
      {login: ENV['GITHUB_USER'], password: ENV['GITHUB_PASSWORD']}
    end
  end
end

get '/status' do
  "ok"
end

post '/' do
  payload = JSON.parse(request.body.read)

  # Write to STDOUT for debugging perpose
  puts "Incoming payload with action: #{payload["action"].inspect}, label: #{payload.dig("label", "name").inspect}, current reviewers: #{payload.dig("pull_request", "reviewers").inspect}"

  pull_request = PullRequest.new(payload, reviewer_pool: JSON.parse(ENV['REVIEWER_POOL']), label: ENV['PR_LABEL'], strategy: ENV['STRATEGY'])
  if pull_request.needs_assigning?
    puts "Assigning #{pull_request.reviewers.inspect} to PR from #{pull_request.creator}"
    pull_request.add_comment!
    pull_request.set_reviewers!
  else
    puts "No need to assign reviewers"
  end
end
