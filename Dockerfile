FROM ruby:2.4-onbuild
ENV LANG C.UTF-8
CMD ruby get_rss.rb > rss.html
