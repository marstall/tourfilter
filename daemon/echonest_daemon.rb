
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
  SharedEvent.find_all_unique.each{|se|
    puts se.summary
    articles = Echonest.new.download_and_save_articles_for(se.summary)
    articles.each{|article|
      puts "\t\t" + article.domain
    }
  }
end

def main(args)
  ActiveRecord::Base.establish_connection("shared")
  begin
    _crawl = false
    $debug = false;
    _crawl=true if args.index("crawl")
    $debug=true if args.index("debug")
    @logger = Logger.new("daemon.log")
    @logger.level = Logger::DEBUG
    if _crawl
      header "crawling"
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
  puts "Tourfilter Echonest Daemon: imports articles from echonest for terms with active matches"
  puts <<-S
    Usage: ruby echonest_daemon.rb 
    [crawl]
    S
  puts "Author: chris marstall Feb 2011"
  exit
else
  puts "for usage: ruby echonest_darmon.rb help"
end
main(ARGV)
