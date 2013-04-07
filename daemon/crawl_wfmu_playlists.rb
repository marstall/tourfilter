# daemon for tourfilter which:
#   1. loads all urls from the page table
#   2. crawls the value of these urls and puts them into the body column of the page table
#   3. for each user, performs each saved search on all pages in the appropriate metros
#   4. for each match, creates a record in the match table with status of "new"
#   5. when all is complete, for each user, find all new matches, concatenated a report of them
#       and send the report in an email to the user's on-file email address
require "rubygems"
require "net/http"
require "logger"
require 'open-uri'
require_gem "activerecord"
require_gem "actionmailer" 
require "../app/models/playlist.rb"
require "../app/models/term.rb"



def initialize_daemon
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://localhost:3000"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_development")
    ActionMailer::Base.server_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
    }
  else
    @tourfilter_base="http://www.tourfilter.com"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"127.0.0.1",
      :username=>'chris',
      :password=>'chris',
      :database=> "tourfilter_boston")
    ActionMailer::Base.server_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
    }
  end
end

def fetch_url(url_text)
    user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    obj = open(url_text, "User-Agent" => user_agent)
    obj.read
end

def header (s)
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end


def crawl(first,last)
  header "crawling playlists #{first}-#{last}"
  url_base = "http://wfmu.org/playlists/shows/"
  first.upto(last) {|i|
      url="#{url_base}#{i}"
      puts "crawling #{url} ..."
      begin
        body = fetch_url(url)
        puts "                                                  OK #{body.size} bytes"
      rescue
        puts "                                                            ERROR, continuing"
      end
      if body =~ /starttime/
        puts "                                                                      match, saving"
        playlist=Playlist.new
        playlist.source="wfmu"
        playlist.url=url
        playlist.body=body
        playlist.show_id=String(i)
        playlist.save
      end
    }
  
end

def parse(first,last)
  header "parsing playlists #{first}-#{last}"
  first.upto(last) {|i|
      begin
        playlist=Playlist.find(i)
      rescue =>e
        puts e
      end  
      if playlist
        puts "parsing playlist at #{playlist.url}..."
        playlist.find_and_save_tracks
      end
    }
end

def update_term_track_counts
  Term.find(:all).each{|term|
    term.num_tracks=Track.count_by_term(term.text)
    term.save
    puts "#{term.text} has #{term.num_tracks} tracks."
    }
end

def main(args)
  _update_counts=false
  _update_counts=true if !args.index("update_counts").nil?
  _parse=false
  _parse=true if !args.index("parse").nil?
  _crawl=false
  _crawl=true if !args.index("crawl").nil?
  first = args[0]
  begin
    last = Integer(args[1])
  rescue
    last = first
  end
  initialize_daemon
  crawl(Integer(first),Integer(last)) if _crawl
  parse(Integer(first),Integer(last)) if _parse
  update_term_track_counts if _update_counts
end

# program entry point
if (!ARGV.index("help").nil?)
  puts "Tourfilter WFMU playlist crawler: downloads all wfmu playlists that have track-specific start times"
  puts "Usage: ruby crawl_wfmu_playlist.rb first last [crawl] [parse] [update_counts] [help]"
  puts "Author: chris marstall Apr 2006"
  exit
else
  puts "for usage: ruby daemon.rb help"
end
main(ARGV)


