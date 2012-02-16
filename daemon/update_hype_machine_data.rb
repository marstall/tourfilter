$mode='daemon'
require 'rss/1.0'
require 'rss/2.0'
require 'rss/dublincore'
require 'rss/syndication'
require 'rss/content'
require 'rss/trackback'

require "rubygems"
require "../config/environment.rb"
require "net/http"
require "logger"
require 'open-uri'
require "../app/models/playlist.rb"
require "../app/models/term.rb"
require "../app/models/shared_term.rb"
require "../app/models/shared_event.rb"
require "../app/models/match.rb"
require "../app/models/track.rb"
require "../app/models/source.rb"
require "../app/models/exception_mailer.rb"



def initialize_daemon
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://www.tourfilter.local:3000/"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :username=>'chris',
      :password=>'chris',
      :database=> "tourfilter_shared")
    ActionMailer::Base.smtp_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
    }
  else
    @tourfilter_base="http://www.tourfilter.com/"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"127.0.0.1",
      :username=>'chris',
      :password=>'chris',
      :database=> "tourfilter_shared")
    ActionMailer::Base.smtp_settings = {
      :address => "tourfilter.com",
      :domain => "ruby"
    }
  end
end

def fetch_url(url_text)
#    user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    user_agent = "tourfilter.com crawler - email info@tourfilter.com"
    obj = open(url_text, {"User-Agent" => user_agent})
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
  Term.find_all_with_hype_tracks.each{|term|
    term.num_mp3_tracks=Track.count_by_term_text(term.text,'mp3')
    term.save
    puts "#{term.text} has #{term.num_tracks} mp3 tracks."
    }
end

def crawl_hm
  url1="http://hypem.com/playlist/artist/"
  url2="/rss/1/feed.xml"
  shared_events = SharedEvent.find_all_unique
  puts "found #{shared_events.size} upcoming shows to get hype machine tracks for"
  done_terms=Hash.new
  shared_events.each{|shared_event|
    begin
      term_text=original_term_text=shared_event.summary
      if done_terms[original_term_text]  
        puts "already done, skipping."
        next
      end
      done_terms[term_text]=true
      shared_term=SharedTerm.find_by_text(term_text)
      if not shared_term
        shared_term=SharedTerm.new
        shared_term.text=term_text
        shared_term.save
      end
      term_text = term_text.gsub(" ","+")
      term_text.gsub!(/\.\!\,/,"")
      url="#{url1}#{term_text}#{url2}"
      puts url
      begin
        rss_source = fetch_url(url)
      rescue => e
        puts e
        next
      rescue TimeoutError
        puts $!
        next
      end
      #puts rss
        rss = RSS::Parser.parse(rss_source,false)
        puts term_text
      i=0
      rss.items.each{|item|
        puts "                            "+item.guid.content
        track=Track.new
        track.term_text=original_term_text
        track.band_name=original_term_text
        track.playlist_url=item.link
        track.description=item.description
        track.url=item.guid.content
        track.file_type='mp3'
        track.source_reference="hype"
        track.status="valid"
        track.save
        i+=1
      }
      shared_term.num_mp3_tracks=i
      shared_term.save
      expire_term_caches(shared_event)
    rescue => e
      handle_exception e
    end
  }
end

def expire_term_caches(shared_event)
  return false if not shared_event
  url="#{@tourfilter_base}#{shared_event.metro_code}/data/expire_term_caches/#{shared_event.url_summary}"
  puts "expiring term caches for term '#{shared_event.summary}'"
  puts "                  #{url}..."
  result = fetch_url(url)
  puts "                           #{result}"
  result=="success"
end


def delete_existing_hm
    Track.delete_all(["source_reference=?","hype"])
end

def handle_exception (e)
  ExceptionMailer.logger=@logger
  ExceptionMailer.template_root="../app/views"
  ExceptionMailer::deliver_snapshot("#{@metro_code} daemon",e) 
  puts e if e
  puts e.backtrace.join("\n") if e
end

def main(args)
  begin
    initialize_daemon
    header("deleting existing hype machine tracks")
    delete_existing_hm
    header("crawling hype machine")
    crawl_hm
    header("updating term_track counts")
    update_term_track_counts
  rescue => e
    handle_exception e
  end
end

# program entry point
if (!ARGV.index("help").nil?)
  puts "Tourfilter Hype Machine crawler:"
  puts "Usage: ruby update_hype_machine_data.rb <metro_code> [help]"
  puts "Author: chris marstall Apr 2006"
  exit
else
  puts "for usage: ruby daemon.rb help"
end
main(ARGV)


