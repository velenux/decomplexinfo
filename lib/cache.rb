# encoding: utf-8

# Copyright (C) Gilberto "Velenux" Ficara <g.ficara@stardata.it>
# Distributed under the terms of the GNU GPL v3 or later

require 'digest'
require 'fileutils'

class CacheHandler
  def initialize(basedir)
    @basedir = basedir
  end

  def save(entry_id, entry_content)
    entry_name = Digest::SHA256.hexdigest(entry_id)
    entry_path = File.join(@basedir, entry_name[0] , entry_name[1])
    begin
      puts "Creating '#{entry_path}'"
      FileUtils.mkdir_p(entry_path)
      puts "Saving entry content to #{entry_name}"
      File.open(File.join(entry_path, entry_name), 'w') { |file| file.write(entry_content) }
      return true
    rescue => e
      puts "Error #{e} while saving the entry"
      raise e
      return false
    end
  end

  def load(entry_id)
    entry_name = Digest::SHA256.hexdigest(entry_id)
    entry_path = File.join(@basedir, entry_name[0] , entry_name[1], entry_name)
    if File.exists?(entry_path)
      return File.read(entry_path)
    end
    return nil
  end
end
