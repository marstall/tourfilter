# daemon for all-cities search which:
# loops through all metros
# retrieves ical for each metro
# deletes all shows for that metro
# loops through each ical element for that metro
# for each, inserts new row into database

begin
  require 'rubygems'
  require 'icalendar'
end
require "../config/environment.rb"

require 'timeout'
require "net/http"
require "logger"
require 'open-uri'
require "../app/models/shared_event.rb"
require "../app/models/metro.rb"
require "../app/models/exception_mailer.rb"

tourfilter_base="http://www.tourfilter.local:3000/boston"
SETTINGS = YAML.load(File.open("../config/settings.yml"))

def initialize_daemon(metro_code)
  SETTINGS['date_type']='us'
  SETTINGS['date_type']='uk' if metro_code=="london" or metro_code=="melbourne" or metro_code=="dublin"
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://www.tourfilter.local:3000/#{metro_code}"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_shared",
      :username=>'chris',
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
    puts "production mode"
    @tourfilter_base="http://www.tourfilter.com/#{metro_code}"
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

def fetch_url2(url_text)
  uri = URI.parse(url_text)
  body=String.new
  begin
    Net::HTTP.start(uri.host,uri.port) {|http|
      @before=Time.new
      http.read_timeout=300
      http.request_get(uri.path) {|response|
        content_type = response['content-type']
    #    raise "Wrong Type: #{content_type}" if content_type !~ /ical/
        num_bytes=0  
        body=String.new
        response.read_body {|s|
  #        puts s
          body+=s
        }
      }
    }
  rescue TimeoutError
    raise "TimeoutError: #{url_text}"
  end
  body
end

def fetch_url(url_text)
  begin
    user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    timeout (1800) do
      obj = open(url_text, "User-Agent" => user_agent)
      obj.read
    end
  rescue TimeoutError
    raise "TimeoutError"
  rescue => e
    handle_exception(e)
    puts "exception loading url '#{url_text}': #{$!}"
  end
end


def header (s)
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end

def fetch(metro)
  header "fetching ical for metro #{metro.code} ..."
  if @local
    url = "http://www.tourfilter.local:3000/ical"
  else
    url = "http://www.tourfilter.com/ical"
  end
  ical = fetch_url2(url)
  raise "retrieved blank ical file from #{url}" if ical.nil? or ical.strip.empty?
  puts "retrieved ical with size of #{ical.size} bytes."
  ical
end

def delete_existing
  header "deleting existing records ..."
  SharedEvent.delete_all
end


def save(metro,ical)

  # first save the imported events so we can detect dupes on the band-name only matches
  save_active_imported_events

  header "saving new records from ical for metro #{metro.code} ..."
  raise "ical is blank for metro #{metro.code}" if ical.nil? or ical.strip.empty?
  cals = Icalendar.parse(ical)
  cal = cals.first

  # Now you can access the cal object in just the same way I created it
    @shared_events_count[metro.code]=0
  cal.events.each{|event|
    dupe = SharedEvent.is_substring_dupe_for_date?(event.summary,event.dtstart)
    if dupe
      puts "+++ substring dupe found. [#{event.summary}] contained in [#{dupe}] #{event.dtstart}"
      next
    end
    puts "saving #{event.summary} at #{event.location} ..."
    shared_event = SharedEvent.new
    shared_event.date = event.dtstart
    shared_event.uid = event.uid
    shared_event.location = event.location
    shared_event.url = nil
    shared_event.metro_code = metro.code
    shared_event.metro_name = metro.name
    shared_event.metro_state = metro.state
    shared_event.metro_lat = metro.lat
    shared_event.metro_lng = metro.lng
    shared_event.summary = event.summary
    shared_event.description = event.description
    shared_event.ticket_json = event.resources.first.gsub("&#58;",":") if event.resources and not event.resources.empty?
    shared_event.save
    @shared_events_count[metro.code]+=1
  }
  
end

def save_active_imported_events
  header "saving new records from imported_events  ..."
  imported_events = ImportedEvent.find_all_future("boston")
  imported_events.each{|event|
    puts "saving #{event.body} at #{event.venue.name} ..."
    shared_event = SharedEvent.new
    shared_event.date = event.date
    shared_event.uid = event.uid
    shared_event.location = event.venue.name
    shared_event.url = event.url
#    shared_event.metro_code = metro.code
#    shared_event.metro_name = metro.name
#    shared_event.metro_state = metro.state
#    shared_event.metro_lat = metro.lat
#    shared_event.metro_lng = metro.lng
    shared_event.summary = event.body
    shared_event.description = event.body
    shared_event.save
    }
end

=begin
 CREATE TABLE `shared_events` (
  `id` int(11) NOT NULL auto_increment,
  `uid` int(11),
  `date` datetime default NULL,
  `location` char(255),
  `url` char(255),
  `source` char(255),
  `summary` char(255),
  `description` text,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  PRIMARY KEY  (`id`),
  KEY `summary` (`summary`),
  KEY `date` (`date`)
) 

BEGIN:VEVENT
DTEND:20070201T200000
DTSTART:20070201T190000
DTSTAMP:20070131T145916
LOCATION:PAs Lounge
URL:http://www.tourfilter.com/martin_finke
UID:10288
SUMMARY:Martin Finke
DESCRIPTION:            The Critique of Pure Reason Presents       MV+EE with the Bummer Road  Ecstatic Peace    <<<Martin Finke>>>    Geoff Farina      DETAILS                    2                    Bluebird    Rotary Club  w Tom \n
END:VEVENT
=end
def main(args)
#  ActiveRecord::Base.logger = Logger.new(STDOUT) #if ENV['RAILS_ENV']!="production"
  begin
    _fetch = false;
    @local = false;
    _delete_existing = false;
    _save = false;
    _fetch=true if args.index("fetch")
    @local= true if args.index("local")
    _delete_existing=true if args.index("delete_existing")
    _save=true if args.index("save")
    @metro=args[args.size-1] if args.index("metro")
    @logger = Logger.new("daemon.log")
    @logger.level = Logger::DEBUG

    initialize_daemon(@metro_code)
    
    if @metro
      puts "performing tasks for metro #{@metro}"
      metros=Metro.find_all_by_code(@metro)
    else
      puts "performing tasks for all metros"
      metro = Metro.find_by_sql("select * from metros")
      metros = Metro.find_all_active
    end
    puts "tasks:"
    puts " => delete existing shared events " if _delete_existing
    puts " => fetch icals" if _fetch
    puts " => save new shared events " if _save
    @shared_events_count=Hash.new
    metros.each{|metro|
      begin
        ical = fetch(metro) if _fetch
        delete_existing if _delete_existing
        save(metro,ical) if _save
      rescue => e
        handle_exception e
      end
      total_shared_events=0
      puts "totals:"
      @shared_events_count.each_key{|metro|
        puts "#{metro} => #{@shared_events_count[metro]}"
        total_shared_events+=@shared_events_count[metro]
      }
      puts "--------------------------"
      puts "all cities => #{total_shared_events}"
    }
  rescue => e
    handle_exception e
  end
end

def handle_exception (e)
  puts e if e
  puts e.backtrace.join("\n") if e
  ExceptionMailer.logger=@logger
  ExceptionMailer.template_root="../app/views"
  ExceptionMailer::deliver_snapshot("#{@metro_code} daemon",e) 
end


# program entry point
if (!ARGV.index("help").nil? or ARGV.empty?)
  puts "Tourfilter All-cities Daemon: retrieves icals from all metros, deletes existing events in shared events table, saves new events"
  puts "Usage: ruby all_cities_daemon.rb [fetch] [delete_existing] [save] [metro <metro_code>] [help]"
  puts "Author: chris marstall Jan 2007"
  exit
else
  puts "for usage: ruby all_cities_daemon.rb help"
end
main(ARGV)



