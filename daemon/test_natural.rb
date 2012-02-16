$mode='daemon'

# test harness for tourfilter which:
# 1. takes as input a lsws log file containing google searches and redirects
# 2. extracts tourfilter path and google keywords
# 3. looks on tourfilter page to see if there is an event there.
# 4. correlates searches with redirects, 
# 5. outputs list of keywords/band names for which:
#       - there was a main_show click
#       - there was a popular/related/blind click
#       - there was no click
#       - for no main_show click artists, links to stubhub/ticketmaster search for manual verification of whether there was a show

require "rubygems"
require "~/tourfilter/config/environment.rb"
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

# ["tourfilter"] 12.197.183.194 - - [11/Mar/2010:13:47:20 -0500] 
# "GET /nashville/my-morning-jacket HTTP/1.1" 200 7403 
# "http://www.google.com/search?q=mmj+nashville&ie=utf-8&oe=utf-8&aq=t&rls=org.mozilla:en-US:official&client=firefox-a" 
# "Mozilla/5.0 (Windows; U; Windows NT 5.1; en-US; rv:1.9.2) Gecko/20100115 Firefox/3.6" "www.tourfilter.com"

def extract_keywords(url)
  keywords=Array.new
  if url=~/google/
    engine='google'
    tokens = URI::decode(url).split(/[?&]/)
    tokens[1..tokens.size].each{|t|
        name_val = t.split("=")
        if name_val[0]=='q'
          keywords=name_val[1].split("+")
          break
        end
      }
  else
    return nil,nil,nil,nil,nil
  end
  keywords_without_metro=Array.new
  metro_code=nil
  skip=false
  keywords.each_with_index{|keyword,i|
    if skip
      skip=false
      next
    end
    keyword2= keyword+" "+ keywords[i+1] if i+1<keywords.size
      keyword.strip.downcase!
      if @metros[keyword]
        metro_code=keyword
      elsif i+1<keywords.size and @metros[keyword2]
        metro_code=keyword2
        skip=true
      else
        keywords_without_metro<<keyword
      end
    }
  return engine,keywords.join(" "),metro_code,keywords_without_metro.join(" ")
end

=begin
CREATE TABLE `search_clicks` (
  `id` int(11) NOT NULL auto_increment,
  `created_at` datetime default NULL,
  `date` datetime default NULL,
  `ip_address` char(16) default NULL,
  `path` char(255) default NULL,
  `domain` char(64) default NULL,
  `search_engine` char(64) default NULL,
  `referer` char(255) default NULL,
  `length` int default NULL,
  `result_code` int default NULL,
  `user_agent` char(255) default NULL,
  `metro_code` varchar(32) default NULL,
  `source` char(16) default NULL,
  `term_text` varchar(255) default NULL,
  `keywords` varchar(255) default NULL,
  `keywords_without_metro` varchar(255) default NULL,
  
  PRIMARY KEY  (`id`),
  KEY `created_at` (`created_at`),
  KEY `term_text` (`term_text`)
)
=end

def parse_line(line)
  h=Hash.new
  tokens=line.split(/\s/)
  h[:ip_address]=tokens[1]
  h[:date]=(tokens[4]+" "+tokens[5]).gsub(/[\[\]]/,"")
  h[:path]=tokens[7]
  h[:result_code]=tokens[9]
  h[:length]=tokens[10]
  h[:referer]=tokens[11]
  h[:search_engine],h[:keywords],h[:metro_code],h[:keywords_without_metro] = extract_keywords h[:referer]
  user_agent=""
  tokens[12..tokens.size].each{|t|
      user_agent+=t+" "
      break if t=~/\"$/
    }
  h[:user_agent]=user_agent.strip.gsub("\"","")
  h[:domain]= tokens[tokens.size-1]
  
  #term_text
  t=h[:path].split("/")
  h[:term_text]= t[2].gsub("-"," ") if t and t.size==3 and @metros[t[1]] 
  return h
end

def get_sessions(filename)
  sessions=Hash.new
  lines = filename.split(/[\r\n]/)
#  parse_line lines[0]
  lines.each{|line|
    h = parse_line line
    if h[:search_engine]=='google'
      puts "#{h[:path]}\t\t\t\t#{h[:term_text]}\t\t\t\t#{@metros[h[:metro_code]]}\t\t\t\t"+(h[:keywords]||"")
      SearchClick.new(h).save 
    end
  }
end

def main(args)
  @metros = Metro.code_and_name_hash
  puts @metros.inspect
  
  filename=args[0]
#  ActiveRecord::Base.establish_connection("shared")
  begin
    sessions=get_sessions(File.read(filename))
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
  puts "You must enter a filename."
  exit
end
main(ARGV)
