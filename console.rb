require 'bundler'
require 'irb'
Bundler.require
Dotenv.load

# Let the library traverse all pages, most querries won't fetch large lists anyway
Octokit.auto_paginate = true
@gh_client = Octokit::Client.new(access_token: ENV['GITHUB_TOKEN'])

IRB.start
Kernel.exit
