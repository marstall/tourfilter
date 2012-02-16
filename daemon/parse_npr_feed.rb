$mode='import_daemon'

# parse npr artist ides
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

=begin
CREATE TABLE `npr_artists` (
  `id` int(11) NOT NULL auto_increment,
  `name` varchar(255) NOT NULL default '',
  PRIMARY KEY  (`id`)
)
=end

def main(args)
  ActiveRecord::Base.establish_connection("shared")
  if File.exists?(args[0])
    text,foo =  File.read(args[0]),true 
  else
    puts "can't find file"
  end
  puts text.size
  lines = text.split(/$/)
  puts lines.size
  lines.each{|line|
    line.strip!
    tokens = line.split(/\t/)
    puts tokens[0]+":"+tokens[1]
    na = NprArtist.new
    na.artist_id=tokens[1]
    na.name=tokens[0]
    na.normalized_name=Term.normalize_text(tokens[0])
    na.save 
    }
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
