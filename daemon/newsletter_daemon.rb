$mode='daemon'
# check_remote_mp3s daemon for tourfilter which:
# loops through all MP3s
# for each:
#   fetch the mp3, following redirects
#   verify that the file is an MP3
#   verify that the file loads within n seconds
#   mark the track row with the status outcome and the ttr
# update all terms' mp3 track counts

require "rubygems"
require "../config/environment.rb"

require "net/http"
require "logger"
#require 'open-uri'
require "../app/models/playlist.rb"
require "../app/models/term.rb"
require "../app/models/track.rb"
require "timeout" 
#require "../app/models/s3.rb"

include ProfileModule

def header (s)
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end

def initialize_daemon(metro_code)
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://localhost:3000"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_#{metro_code}")
    ActionMailer::Base.smtp_settings = {
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
      :database=> "tourfilter_#{metro_code}")
    ActionMailer::Base.smtp_settings = {
        :address => "tourfilter.com",
        :domain => "ruby"
      }
  end
end

def send_weekly_and_monthly
  if @user
    puts @user
    users = [User.find_by_name(@user)] 
    users = [User.find_by_email_address(@user)] if users.nil? or users.first.nil? or users.empty?
    users = [User.find(@user)] if users.nil? or users.first.nil? or users.empty? 
    puts "processing single user: #{users.first.name}"
    num_users=1
  else
    users = User.find_all_needing_newsletter
    num_users=users.size
    puts "processing #{num_users} users."
  end
#  user = User.find_by_name("chris")
  users.each_with_index{|user,i|
      days_ago = 
      begin
        if user.newsletter_last_sent_on!=nil
          date = user.newsletter_last_sent_on.to_datetime
  		    hours,ignore,ignore,ignore=Date::day_fraction_to_time(DateTime::now()-date)
  		    hours/24
		    else
		      100
	      end
	    end
      start_timer('newsletter')
      if user.wants_weekly?
#        Event.weekly_newsletter_sent(user) 
        if users.size>1 and days_ago<5
          puts "skipping #{user.name}, too soon (#{days_ago} days)" 
          next 
        end
      end
      if user.wants_monthly? #or user.wants_weekly?
#        Event.monthly_newsletter_sent(user) 
        if users.size>1 and days_ago<25
          puts "skipping #{user.name}, too soon (#{days_ago} days)" 
          next 
        end
      end
      
      email = NewsletterMailer::deliver_newsletter(@metro_code,user) 
      user.newsletter_last_sent_on=DateTime::now()
      user.save_with_validation(false)
      if user.wants_weekly?
        Event.weekly_newsletter_sent(user) 
        Action.weekly_newsletter_sent(@metro_code,user)
      end
      if user.wants_monthly?
        Event.monthly_newsletter_sent(user) 
        Action.monthly_newsletter_sent(@metro_code,user)
      end
      elapsed = end_timer('newsletter',false)
      puts "#{i+1}/#{num_users} #{user.name} sent ok. (#{elapsed}ms)"
  }
end

def main(args)
#  ActiveRecord::Base.logger = Logger.new(STDOUT) 
  @metro_code = args[0]
  if not @metro_code
    puts "Fatal error: You must specify a metro code. Nothing was done."
    return
  end
  header "running on metro #{@metro_code}!"
  initialize_daemon(@metro_code)

  @user=nil
  @user=args[args.index("user")+1] if args.index("user")

  _send_weeklies=false
  _send_weeklies=true if !args.index("send_weeklies").nil?
  
  send_weekly_and_monthly
end

# program entry point
if (!ARGV.index("help").nil?)
  puts "Tourfilter Newsletter daemon: sends weekly and monthly newsletters"
  puts "Usage: ruby newsletter_daemon.rb [metro_code] <user [name|email address]>"
  puts "Author: chris marstall 2008"
  exit
else
  puts "for usage: ruby newsletter_daemon.rb help"
end
main(ARGV)


  