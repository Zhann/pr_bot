require 'bundler'
require 'json'
Bundler.require
Dotenv.load

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
    # When adding label "for-review" and no assignees yet
    @payload["action"] == "labeled" && @payload.dig("label", "name") == @label && @payload.dig("pull_request", "assignees") == []
  end

  def set_assignees!
    gh_client.update_issue(repo_id, pr_number, assignees: assignees)
  rescue Octokit::UnprocessableEntity => e
    puts "Unable to add set assignees: #{e.message}"
  end

  def add_comment!
    gh_client.add_comment(repo_id, pr_number, message)
  end

  def assignees
    @assignees ||= @reviewer_pool.map do |group| 
      (group-[creator]).sample
    end
  end

  def creator
    @payload.dig("pull_request", "user", "login")
  end

  private

  def message
    assignees_s = assignees.map { |a| "@#{a}" }.join(" and ")
    "Thank you @#{creator} for your contribution! My random determinator has determined that #{assignees_s} shall review your code"
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
  puts "Incoming payload with action: #{payload["action"].inspect}, label: #{payload.dig("label", "name").inspect}, current assignees: #{payload.dig("pull_request", "assignees").inspect}"

  pull_request = PullRequest.new(payload, reviewer_pool: JSON.parse(ENV['REVIEWER_POOL']), label: ENV['PR_LABEL'])
  if pull_request.needs_assigning?
    puts "Assigning #{pull_request.assignees.inspect} to PR from #{pull_request.creator}"
    pull_request.add_comment!
    pull_request.set_assignees!
  else
    puts "No need to assign"
  end
end
