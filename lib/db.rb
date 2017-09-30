# encoding: utf-8

# Copyright (C) Gilberto "Velenux" Ficara <g.ficara@stardata.it>
# Distributed under the terms of the GNU GPL v3 or later

require 'sequel'
require 'logger'

DB = Sequel.connect('sqlite://decomplexinfo.db')
DB.loggers << Logger.new('db-debug.log')

# MODELS
# RssEntry
DB.create_table? :rss_entries do
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
