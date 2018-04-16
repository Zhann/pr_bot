# PR Bot

A Bot that assigns reviewers to github PR's.

When you add a specific label to a pull request, this bot will assign
reviewers. It picks one random reviewer per review "group". PR Bot will not
re-assign already assigned PR's. If you want to reassign a PR, first remove the
current assignees.

This bot will need the username and password of a github user with access to
the repo OR a github access token.

## Setup

1. Run this Sinatra app with the following env vars
  * GITLAB_TOKEN: an access token for a user with `repo` access scope.
  * GITLAB_ENDPOINT: the URL for Gitlab's API
  * PR_LABEL: the label's text string to trigger the bot.
  * REVIEWER_POOL: a list of github username lists.
1. Add a webhook to your github repository
  * If this bot is running at prbot.example.com, set the webhook to `https://prbot.example.com/`.
  * Set the Content type to `application/json`.
  * Don't set a secret.
  * Choose "Let me select individual events" and check only "Pull request".

## Usage

Make sure you're running ruby 2.1+, and install the gem dependencies:

```bash
bundle install
```

You can run the Sinatra app like so, (or use a [.env](https://github.com/bkeepers/dotenv) file).

```bash
GITHUB_TOKEN=5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8 PR_LABEL=for-review REVIEWER_POOL=["user1", "user2", "user3"] ruby app.rb
```

## Docker

Alternatively you can run this with docker.

```bash
docker run -p 4567:4567 -e "PR_LABEL=for-review" -e "GITHUB_TOKEN=5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8" -e 'REVIEWER_POOL=["user1", "user2", "user3"]' andruby/pr_bot
```

### Build and run

```bash
docker build -t pr_bot .
docker run -p 4567:4567 -e "PR_LABEL=for-review" -e "GITHUB_TOKEN=5baa61e4c9b93f3f0682250b6cf8331b7ee68fd8" -e 'REVIEWER_POOL=["user1", "user2", "user3"]' pr_bot
```
