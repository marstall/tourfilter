# daemon for all-cities search which:
# loops through all metros
# retrieves ical for each metro
# deletes all shows for that metro
# loops through each ical element for that metro
# for each, inserts new row into database

begin
  require 'rubygems'
  require_gem 'icalendar', ">= 0.96"
rescue LoadError
  require 'icalendar'
end

require 'timeout'
require "rubygems"
require "net/http"
require "logger"
require 'open-uri'
require_gem "activerecord"
require_gem "actionmailer" 
require "../app/models/shared_event.rb"
require "../app/models/metro.rb"
require "../app/models/exception_mailer.rb"



tourfilter_base="http://boston.tourfilter.local:3000"
SETTINGS = YAML.load(File.open("../config/settings.yml"))

def initialize_daemon(metro_code)
  SETTINGS['date_type']='uk' if metro_code=='london'
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://boston.tourfilter.local:3000"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_shared",
      :username=>'chris',
      :password=>'chris'
      )
    ActionMailer::Base.server_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
#        :address => "tourfilter.com",
#        :domain => "ruby"
    }
  else
    @tourfilter_base="http://#{metro_code}.tourfilter.com"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"127.0.0.1",
      :username=>'chris',
      :password=>'chris',
      :database=> "tourfilter_all")
    ActionMailer::Base.server_settings = {
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

def tv_stuff
#  facebook_settings = FacebookSetting.find_by_sql("select facebook_userid,tv from facebook_settings")
#  facebook_settings.each{|facebook_setting|
    
end

def main(args)
#  ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['RAILS_ENV']!="production"
  begin
    _fetch = false;
    _delete_existing = false;
    _save = false;
    tv_stuff=true if args.index("tv_stuff")

    @logger = Logger.new("daemon.log")
    @logger.level = Logger::DEBUG

    initialize_daemon(@metro_code)
    
    puts "tasks:"
    puts " => doing tv stuff " if _tv_stuff
    tv_stuff if _tv_stuff
  rescue => e
    handle_exception e
  end
end

def handle_exception (e)
  ExceptionMailer.logger=@logger
  ExceptionMailer.template_root="../app/views"
  ExceptionMailer::deliver_snapshot("#{@metro_code} daemon",e) 
  puts e if e
  puts e.backtrace.join("\n") if e
end


# program entry point
if (!ARGV.index("help").nil? or ARGV.empty?)
  puts "Tourfilter Facebook Daemon: different command line shit for facebook"
  puts "Usage: ruby facebook_daemon.rb [tv_stuff] [help]"
  puts "Author: chris marstall Jun 2007"
  exit
else
  puts "for usage: ruby facebook_daemon.rb help"
end
main(ARGV)



