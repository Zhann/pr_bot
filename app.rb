require 'bundler'
require 'json'
Bundler.require
Dotenv.load

set :bind, ENV['BIND'] || 'localhost'

# Required ENV vars:
#
# GITHUB_USER: botsname
# GITHUB_PASSWORD: YourPwd
# REVIEWER_POOL: [["andruby","x","y"],["a","b","c"]]
# PR_LABEL: for-review

class PullRequest
  def initialize(payload, reviewer_pool:, label:)
    @payload = payload
    @reviewer_pool = reviewer_pool
    @label = label
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
    @reviewers ||= @reviewer_pool.map do |pool|
      (pool["names"]-[creator]).sample(pool["count"])
    end.flatten
  end

  def creator
    @payload.dig("pull_request", "user", "login")
  end

  private

  def message
    reviewers_s = reviewers.map { |a| "@#{a}" }.join(" and ")
    "Thank you @#{creator} for your contribution! My random determinator has determined that #{reviewers_s} shall review your code"
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

  pull_request = PullRequest.new(payload, reviewer_pool: JSON.parse(ENV['REVIEWER_POOL']), label: ENV['PR_LABEL'])
  if pull_request.needs_assigning?
    puts "Assigning #{pull_request.reviewers.inspect} to PR from #{pull_request.creator}"
    pull_request.add_comment!
    pull_request.set_reviewers!
  else
    puts "No need to assign reviewers"
  end
end
