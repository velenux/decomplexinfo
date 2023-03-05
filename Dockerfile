FROM ruby:3

ENV LANG C.UTF-8

# throw errors if Gemfile has been modified since Gemfile.lock
RUN bundle config --global frozen 1

WORKDIR /usr/src/app

COPY Gemfile ./
COPY Gemfile.lock ./
COPY get_rss.rb ./
COPY lib ./

RUN bundle install

CMD ["./get_rss.rb"]
