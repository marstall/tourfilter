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
require "hpricot"
require 'open-uri'
require 'uri'
require_gem "activerecord"
require_gem "actionmailer" 
require "../app/models/parser.rb"
require "../app/models/imported_events.rb"
require "../app/models/shared_events.rb"
require "../app/models/ticketmaster.rb"
$KCODE='u' 
require 'jcode' 

def initialize_daemon(metro_code)
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://www.antiplex.local:3000/"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_shared",
      :username=>'chris',
      :encoding=>'utf8',
      :password=>'chris'
      )
    ActionMailer::Base.smtp_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
#        :address => "tourfilter.com",
#        :domain => "ruby"
    }
  else
    @tourfilter_base="http://www.tourfilter.com/"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"127.0.0.1",
      :username=>'chris',
      :password=>'chris',
      :encoding=>'utf8',
      :database=> "tourfilter_shared")
    ActionMailer::Base.server_settings = {
      :address => "tourfilter.com",
      :domain => "ruby"
    }
  end
  puts "daemon initialized."
end

def fetch_url(url_text)
  begin
    user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    obj = open(url_text, "User-Agent" => user_agent)
    obj.read
  rescue => e
    handle_exception(e)
    puts "exception loading url '#{url_text}': #{$!}"
  end
    
end

def url(foo)
  super
end
  
def perform_ticketmaster_crawl
  Ticketmaster.crawl
end

def perform_crawl
  perform_ticketmaster_crawl
end


# will either return the number of ms it took to load num_bytes_required bytes, or throw an exception.
# follows any redirections (up to 5)
 def get_final_url(uri_str,limit=5)
#   puts "getting final url for #{uri_str} ... "
      if limit==0
        puts "HTTP redirect too deep"
      end
      uri = URI.parse(uri_str)
#      raise ArgumentError, 'HTTP redirect too deep' if limit == 0
      response=Object.new
      begin
        timeout(7) do
            Net::HTTP.start(uri.host) {|http|
              response = http.request_head(uri.path)
              case response
                when Net::HTTPSuccess     then 
#                  puts "\t\t\t\t\t\t\t\t\t\t!!!success"
                  response
                when Net::HTTPRedirection then 
                  puts "redirecting to #{response['location']}"
                  uri_str = get_final_url(response['location'].gsub(/\s/,"%20"), limit - 1)
                else
                  response.error!
                end
            }
#          puts "response headers:"
          response.each_key{|key|
#            puts "#{key}: #{response[key]}"
          }
        end
    rescue TimeoutError
      puts "\t\t\t\t\t\t\t\t\t\t???timed out"
    rescue => e
      puts "\t\t\t\t\t\t\t\t\t\t???#{e}"
    end
#    puts "returning #{uri_str} from get_final_url"
    uri_str
 end
 
def header (s)
  return unless s
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end

def main(args)

  begin
    @file_root="../public/images/publicity/"
    _perform_crawl=false
    @debug = false;
    _url = nil
    _perform_crawl=true if args.index("crawl")
    @debug=true if args.index("debug")
    @place_name=args[args.size-1] if args.index("place")
    @logger = Logger.new("daemon.log")
    @logger.level = Logger::DEBUG

    initialize_daemon(@metro_code)
    if (_perform_crawl) 
      header "starting crawl"
      perform_crawl
    end
#  rescue => e
#    handle_exception e
  end
end

def handle_exception (e)
begin
  ExceptionMailer.logger=@logger
  ExceptionMailer.template_root="../app/views"
  ExceptionMailer::deliver_snapshot("#{@metro_code} daemon",e) 
  puts e if e
  puts e.backtrace.join("\n") if e
rescue 
rescue Timeout::Error
end
end

#  ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['RAILS_ENV']!="production"


# program entry point
if (!ARGV.index("help").nil? or ARGV.empty?)
  puts "Tourfilter Import Events Daemon: imports events from ticketmaster, live nation, etc."
  puts "Usage: ruby import_events.rb  [debug] [crawl] [place n]"
  puts "Author: chris marstall Dec. 2007"
  exit
else
  puts "for usage: ruby import_events.rb help"
end
main(ARGV)
