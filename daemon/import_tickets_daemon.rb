$mode='import_daemon'

# daemon for tourfilter which:
#   1. loads all urls from the page table
#   2. crawls the value of these urls and puts them into the body column of the page table
#   3. for each user, performs each saved search on all pages in the appropriate metros
#   4. for each match, creates a record in the match table with status of "new"
#   5. when all is complete, for each user, find all new matches, concatenated a report of them
#       and send the report in an email to the user's on-file email address
require "rubygems"
require "../config/environment.rb"
require 'mechanize'
require "net/http"
require "logger"
require "hpricot"
require 'open-uri'
require 'uri'
require 'text'

$KCODE='u' 
require 'jcode' 

    
begin
  require '/usr/local/lib/ruby/gems/1.8/gems/mechanize-0.7.0/lib/www/mechanize.rb'
rescue MissingSourceFile
end
require  'mechanize'


def header (s)
  return unless s
  line = "****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end


def crawl
  if @id
    puts "loading imported_event with id #{@id}"
    events = [ImportedEvent.find(@id)]
  else
    events = ImportedEvent.find_future_valid(@source,@metro_code)
  end
  puts "found #{events.size} #{@source||''} events."
  events.each{|event|
    begin
      event.find_and_save_ticket_offers(events.size,@fast_forward)
    rescue WWW::Mechanize::ResponseCodeError      
      puts "ResponseCodeError"
    rescue TimeoutError
      puts "TimeoutError"
    rescue SocketError
      puts "SocketError"
    rescue NoMethodError
      puts "NoMethodError"
    rescue Exception
      puts "Exception"
    end

  }
end

def main(args)
  ActiveRecord::Base.establish_connection("shared")
  begin
    _import_ticketmaster_tickets=false
    _import_ticketnetwork_tickets=false
    _import_stubhub_tickets=false
    _import_ticketsnow_tickets=false
    _crawl = false
    _save_tickets=false
    @fast_forward=false
    @fast_forward=true if args.index("fast-forward")
    $debug = false;
    _import_ticketmaster_tickets=true if args.index("import_ticketmaster_tickets")
    _import_stubhub_tickets=true if args.index("import_stubhub_tickets")
    _import_ticketnetwork_tickets=true if args.index("import_ticketnetwork_tickets")
    _import_ticketsnow_tickets=true if args.index("import_ticketsnow_tickets")
    _save_tickets=true if args.index("save_tickets")
    _crawl=true if args.index("crawl")
    $debug=true if args.index("debug")
    @place_name=args[args.size-1] if args.index("place")
    @logger = Logger.new("daemon.log")
    @logger.level = Logger::DEBUG
    @source=nil
    @source=args[args.index("source")+1] if args.index("source")
    @metro_code=args[args.index("metro_code")+1] if args.index("metro_code")
    @id = args[args.index("id")+1] if args.index("id")
    if _crawl
      header "crawling #{@source}"
      crawl 
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
  puts "Tourfilter Import Tickets Daemon: imports ticket info from ticketmaster, live nation, etc."
  puts <<-S
    Usage: ruby import_tickets_daemon.rb 
    [crawl]
    [import_stubhub_tickets] [import_ticketmaster_tickets] [import_ticketnetwork_tickets] [import_ticketsnow_tickets]
    [debug] [fast-forward] 
    [source <source>]
    [metro_code <metro_code>]
    S
  puts "Author: chris marstall July 2008"
  exit
else
  puts "for usage: ruby import_tickets_daemon.rb help"
end
main(ARGV)
