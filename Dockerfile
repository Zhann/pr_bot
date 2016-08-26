FROM ruby:2.3-alpine
MAINTAINER andruby

# Needed to build eventmachine
RUN apk update && apk add g++ musl-dev make && rm -rf /var/cache/apk/*

RUN mkdir -p /var/www/pr_bot
WORKDIR /var/www/pr_bot
COPY Gemfile .
COPY Gemfile.lock .
RUN bundle install
COPY app.rb .

EXPOSE 80

CMD bundle exec ruby app.rb

