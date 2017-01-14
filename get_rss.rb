# encoding: utf-8

# Copyright (C) Gilberto "Velenux" Ficara <g.ficara@stardata.it>
# Distributed under the terms of the GNU GPL v3 or later

require 'net/http'
require 'uri'
require 'feedjira'
require 'logger'
require 'set'
require 'sequel'

DB = Sequel.sqlite
DB.loggers << Logger.new('db-debug.log')

# MODEL
# RssEntry
DB.create_table :rss_entries do
  primary_key :id
  String   :title, :size => 2048, :required => true
  String   :body,  :text => true, :unique => true
  String   :uri,   :size => 4096, :unique => true, :required => true
  String   :original_uri, :size => 4096, :unique => true, :required => true
  DateTime :published_at
end

class RssEntry < Sequel::Model
  plugin :validation_helpers
  def validate
    super
    validates_presence [:title, :original_uri, :uri]
    validates_unique [:body, :uri, :original_uri]
  end
end


# this is almost straight from net/http documentation: we need it to get the
# real urls when we're following redirections
# FIXME: should cache results
# FIXME: manage wrong/unreachable URIs (raise exception?)
def get_real_url(url, limit=10)
  # return nil when the redirect limit is reached
  return nil if limit == 0

  # we'll work on this
  current_url = url

  # if url is a string, parse it to a URI object
  current_url = URI.parse(url) if url.instance_of? String

  # connect to the uri passed as argument
  response = Net::HTTP.get_response(current_url)
  case response
    when Net::HTTPSuccess then
      # found the final form, return it
      current_url
    when Net::HTTPRedirection then
      # parse the redirect location
      loc = URI.parse(response['location'])

      # next location
      next_url = loc

      # handle relative redirects if required
      next_url = current_url + loc if (loc.scheme.nil? or loc.scheme[0..3] != 'http')

      # recursively fetch the next location
      get_real_url(next_url, limit - 1)
    else
      nil
  end
end # get_real_url()

# we need this to get URI without parameters
# used to get rid of useless utm_source parameters
def get_url_without_params(uri)
  # FIXME: should cache results
  return uri.sub(/\?.*/, '')
end # get_url_without_params

# accepts URIs from a feed
def can_use_simple_url?(uri_list)
  # Creates a list of the URIs without parameters
  uris_wo_params = uri_list.map { |u| get_url_without_params(u) }

  # Checks if there are duplicates in the list. If there are, then the parameters
  # are meaningful (are used to differentiate page content), otherwise they are
  # (probably) just feedburner spam (utm_source)
  uris_wo_params.uniq.count === uris_wo_params.count
end # can_use_simple_url

def get_all_rss(rss_uri_list)
  rss_uri_list.each do |rss_uri|
    # get real url for feed (following redirects) and open it
    begin
      feed = Feedjira::Feed.fetch_and_parse get_real_url(rss_uri)
    rescue => e
      #$stderr.puts "Error on feed #{rss_uri}, #{e}"
      next
    end
    feed.entries.each do |rss_entry|
      begin
        rss_post = RssEntry.create(
          :title => rss_entry.title,
          :body  => rss_entry.summary,
          :uri   => get_real_url(rss_entry.url),
          :original_uri => rss_entry.url,
          :published_at => rss_entry.published
        )
      rescue => e
        #$stderr.puts "Error on post #{rss_entry.url}, #{e}"
        next
      end
    end
  end
end

feeds = []
f = open('my_feeds.txt')
f.each_line do |uri|
  feeds << uri.chomp
end
f.close
get_all_rss(feeds)

template = File.read('index.html')
news_string = ''

RssEntry.where{published_at > (Date.today - 3)}.order(Sequel.desc(:published_at)).each do |rss_entry|
  news_string += "<div class=\"newsentry\"><a href=\"#{rss_entry.uri}\"><h2 class=\"newstitle\">#{rss_entry.title}</h2></a>
<p class=\"date\">published: #{rss_entry.published_at}</p>
<p class=\"newsbody\">#{rss_entry.body}</p>
</div>"
end

puts template.gsub('%%NEWS%%', news_string)
