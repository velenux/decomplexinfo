# encoding: utf-8

# Copyright (C) Gilberto "Velenux" Ficara <g.ficara@stardata.it>
# Distributed under the terms of the GNU GPL v3 or later

require 'net/http'
require 'uri'
require 'feedjira'
require 'logger'
require 'set'

require './lib/db.rb'
require './lib/cache.rb'
require './lib/uri.rb'


# main

log = Logger.new('logs/decomplexinfo.log', 'weekly')

# open my_feeds.txt
f = open('my_feeds.txt')
f.each_line do |uri|
  rss_uri = uri.chomp
  begin
    # get real url for feed (following redirects) and open it
    feed = Feedjira::Feed.fetch_and_parse get_real_url(rss_uri)
  rescue => e
    log.error "Error on feed #{rss_uri}, #{e}"
    next
  end
  feed.entries.each do |rss_entry|
    # skip this if we already have it in the database
    if RssEntry.where{original_uri == rss_entry.url}
      log.debug "DUPLICATE: #{rss_entry.url} found in database"
      next
    end
    # if we don't have it, add it to the database
    begin
      rss_post = RssEntry.create(
        :title => rss_entry.title,
        :body  => rss_entry.summary,
        :uri   => get_real_url(rss_entry.url),
        :original_uri => rss_entry.url,
        :published_at => rss_entry.published
      )
    rescue => e
      log.error "Error on post #{rss_entry.url}, #{e}"
      next
    end
  end
end

# close the filehandle
f.close

template = File.read('template.html')
news_string = ''

RssEntry.where{published_at > (Date.today - 3)}.order(Sequel.desc(:published_at)).each do |rss_entry|
  news_string += "<div class=\"newsentry\"><a href=\"#{rss_entry.uri}\"><h2 class=\"newstitle\">#{rss_entry.title}</h2></a>
<p class=\"date\">published: #{rss_entry.published_at}</p>
<p class=\"newsbody\">#{rss_entry.body}</p>
</div>"
end

File.open('rss.html', 'w') { |file| file.write(template.gsub('%%NEWS%%', news_string)) }
