# encoding: utf-8

# Copyright (C) Gilberto "Velenux" Ficara <g.ficara@stardata.it>
# Distributed under the terms of the GNU GPL v3 or later

require 'net/http'
require 'uri'
require 'feedjira'
require 'sanitize'
require 'logger'
require 'set'

require './lib/db.rb'
require './lib/cache.rb'
require './lib/uri.rb'


# main

log = Logger.new('logs/decomplexinfo.log', 'weekly')

Feedjira.configure do |config|
  config.user_agent = "Mozilla/5.0 (Windows NT 6.1; WOW64; rv:64.0) Gecko/20100101 Firefox/64.0"
end

# open my_feeds.txt
f = open('my_feeds.txt')
f.each_line do |uri|
  entry_counter = 0
  rss_uri = uri.chomp
  begin
    log.info "=== RSS === #{rss_uri}"
    feed = Feedjira::Feed.fetch_and_parse rss_uri
  rescue => e
    log.error "Error on feed #{rss_uri}, #{e}"
    next
  end

  # verify if we can actually use urls without the parameters
  # FIXME: this should be internal to RssEntry
  if can_use_simple_url?( feed.entries.map { |u| u.url } )
    log.debug "SIMPLE_URLS enabled for #{rss_uri}"
    simple_urls = true
  else
    log.debug "SIMPLE_URLS disabled for #{rss_uri}"
    simple_urls = false
  end

  # cycle over the entries
  feed.entries.each do |rss_entry|
    entry_counter += 1
    log.info "=== ENTRY === #{entry_counter} of #{feed.entries.size()}"

    # skip this if we already have this original_uri
    if RssEntry.where(:original_uri => rss_entry.url).count() >= 1
      log.debug "DUPLICATE original_uri found in database"
      next
    end

    # skip this if we already have an article with the same body
    entry_body = Sanitize.fragment(rss_entry.summary, Sanitize::Config::RELAXED)
    if RssEntry.where(:body => entry_body).count() >= 1
      log.debug "DUPLICATE body found in database"
      next
    end

    # remove parameters from the URL if possible, to avoid tracking
    if simple_urls
      entry_url = get_url_without_params( get_real_url(rss_entry.url) )
    else
      entry_url = get_real_url( rss_entry.url )
    end
    #log.debug "<< ORIGINAL  #{rss_entry.url}   (#{rss_entry.url.class})"
    #log.debug ">> REAL      #{entry_url}   (#{entry_url.class})"

    # sanitize the title too
    entry_title = Sanitize.fragment(rss_entry.title, Sanitize::Config::RELAXED)

    # if we don't have it, add it to the database
    begin
      rss_post = RssEntry.create(
        :title => entry_title,
        :body  => entry_body,
        :uri   => entry_url,
        :original_uri => rss_entry.url,
        :published_at => rss_entry.published
      )
      log.info "Added '#{entry_title}'"
    rescue => e
      log.error "Error on #{rss_entry.url} - #{e}"
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
