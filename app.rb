require 'bundler'
Bundler.require
Dotenv.load

gh = Octokit::Client.new(login: ENV['GITHUB_USER'], password: ENV['GITHUB_PASSWORD'])

get '/frank-says' do
  "Put this in your pipe & smoke it!, gh: #{gh.user.inspect}"
end
