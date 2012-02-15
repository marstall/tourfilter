#require "../app/models/imported_events.rb"
#require "../app/models/shared_events.rb"

require 'rubygems'
require 'mechanize'
require "../app/models/venue.rb"
require "../app/models/import_parser.rb"

VENUES_FEED_URL="http://feeds.perfb.com/index.php/download?OEMAIL=chris@tourfilter.com&PX=867521b04f541373ef384d7a5f7a1cc6&DISPLAYFORMAT=PIPE&REVERSEMAPXML=yes&PRODUCTDB_ID=307"
EVENTS_FEED_URL="http://feeds.perfb.com/index.php/download?OEMAIL=chris@tourfilter.com&PX=867521b04f541373ef384d7a5f7a1cc6&DISPLAYFORMAT=PIPE&REVERSEMAPXML=yes&PRODUCTDB_ID=306"

class TicketmasterUKParser < ImportParser
  def crawl(code=nil,fast_forward=false)
    puts "crawling ticketmaster UK venues ..."
    crawl_venues
    puts "crawling ticketmaster UK events ..."
    crawl_events
  end

  def crawl_events
    url = EVENTS_FEED_URL
    puts "fetching #{url}..."
    text = fetch_url_cached(url)
    puts "downloaded #{text.size} bytes, parsing now ..."
    lines = text.split(/$/) 
    puts "#{lines.size} lines."
    num_processed=0
    num_lines=lines.size
    lines.each_with_index{|line,i|
      begin
        tokens = line.split("|")
        venue_code = tokens[38].strip
        venue = Venue.find_by_code(venue_code)
        if venue.nil?
          puts "venue w/code #{venue_code} not found, skipping ...."
          next
        end
        uid = "ticketmaster_uk_#{tokens[0].strip}"
        event  =  ImportedEvent.find_by_uid(uid)
        if not event
          event = ImportedEvent.new 
          event.status='new'
          event.cancelled='no'
        end
#        if date_string=="cancelled"
#          event.cancelled="yes" # preserve previous time if the show is now cancelled
#        else
#          time = Time.parse(date_string)
          # only set time if it's not cancelled
#        end
        # does this event already exist? if not, create it. if so, update existing record.
        event.uid=uid
        time_string = tokens[37]
        date_string = tokens[41]
        begin
          datetime_string = date_string+" "+time_string+" UTC"
          event.date=Time.parse(datetime_string)
        rescue
          puts "can't parse date, skipping ... "
        end
        event.venue_id=venue.id
        event.url=tokens[12]
        event.body=tokens[1]
        event.source='ticketmaster_uk'
        event.level='primary'
        event.save
        puts "#{uid} #{event.date} #{event.body} #{event.url}"
      rescue
        puts "error parsing line #{i}, continuing ..."
      end
    }
  end
  
  def crawl_venues
    url = VENUES_FEED_URL
    puts "fetching #{url}..."
    text = fetch_url_cached(url)
    puts "downloaded #{text.size} bytes, parsing now ..."
    lines = text.split(/$/) 
    puts "#{lines.size} lines."
    num_processed=0
    num_lines=lines.size
    lines.each_with_index{|line,i|
      begin
        tokens = line.split("|")
        code = tokens[0].strip
        venue = Venue.find_by_code(code)
        venue ||= Venue.new
        venue.code=code
        venue.name=tokens[1].strip rescue next
#        venue.affiliate_url_1=tokens[12].strip
#        venue.affiliate_url_2=tokens[13].strip
#        venue.logo_url=tokens[14].strip
        venue.city=tokens[35].strip rescue next
        venue.state="uk"
        venue.zipcode=tokens[36].strip rescue ''
        venue.address=tokens[37].strip rescue ''
        venue.url=tokens[12].strip rescue ''
        venue.source="ticketmaster_uk"
        venue.save
        puts "#{venue.name} in #{venue.address}, #{venue.city} #{venue.zipcode}"
      end
    }
  end
end

#147463|demo theatre||London|||||||||http://ticketsuk.at/tourfilter/147463.html|http://ticketsuk.at/tourfilter?CTY=9&DURL=http://www.ticketmaster.co.uk/demo-theatre-tickets-London/venue/147463?camefrom=CFC_UK_BUYAT&brand=
#|http://media.ticketmaster.co.uk/dbimages/316v.jpg||GBP|||||||||||||||||||London|wc2h 7lr|leicester square||||||||||||||||||||||||||