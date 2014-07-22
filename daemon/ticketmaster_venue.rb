require 'rubygems'
require 'json'
require 'mechanize'
require "../app/models/venue.rb"
require "../app/models/imported_event.rb"
require "import_parser.rb"
require 'digest/md5'

class TicketmasterVenue < Venue
include FileUtils

# 2. crawl venues (daily)
# =>  loop through all venues
# =>  if no events, don't crawl unless last_crawled is null or greater than a month ago
# =>  if events, fetch page 1.
# =>  determine number of pages
# =>  for each page, get all events
# =>    for each event
# =>      does it exist (based on unique event identifier)? if not:
# =>        save artist name, tm artist id, majorcatid,minorcatid, date, time,url,unique event identifier

=begin
select venues.code,left(venues.name,50),venues.status
from venues,metros_venues,metros
where metros_venues.venue_id=venues.id 
  and metros_venues.status='valid'
  and metros_venues.metro_code=metros.code
  and source='ticketmaster'
  and metros.status='active'
=end
  def TicketmasterVenue.find_valid_venues
    # return all source=ticketmaster venues that have a status of 'valid'
    sql = <<-SQL
      select venues.*
      from venues,metros_venues,metros
      where metros_venues.venue_id=venues.id 
        and metros_venues.status='valid'
        and source='ticketmaster'
        and metros_venues.metro_code=metros.code
        and metros.status='active'
    SQL
    find_by_sql(sql)
  end

  def extract_total_events(body)
    # first determine how many pages there are
    doc = Hpricot(body)
    pagination = (doc/"th.lid-sub").inner_html
    #<th colspan="3" class="lid-sub">&nbsp;1 - 20&nbsp;of&nbsp;293            <a href="http://www.ticketmaster.com/venue/237569?start=21&rpp=20&searchtype=">next</a></th>
    total_events=pagination.scan(/\d+/)[2].strip rescue 0
    total_events=Integer(total_events)
    total_events=1000 if total_events>1000
    return total_events
  end

  # look in cache - if it finds it there, return it. else wait <delay> seconds and fetch it
  def fetch_url(agent,url,delay=0) # returns body + was_cached
    cache_timeout=12*60*60 # 1/2 day
    digest = Digest::MD5.hexdigest(url)
    filename="/tmp/tourfilter/#{digest}"
    # return the cached version if it exists and it is less that <cache_timeout> seconds old
    return File.read(filename),true if File.exists?(filename) and Time.now-File.atime(filename)<cache_timeout
#    atime = File.atime(filename)
#    puts "file exists?: #{File.exists?(filename)}"
#    puts "atime: #{atime}"
#    puts "now: #{Time.now}"
#    puts "cache_timeout: 180"
#    puts "Time.now-atime: #{Time.now-atime}"
    sleep delay
    page = agent.get(url)
#    puts "creating filename for url #{url}: #{filename}"
    rm_rf(filename)
    file = File.new(filename,"w")
    file.write(page.body)
    file.close
    return page.body,false
  end

  def fetch
    agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
    agent.set_proxy("psychoastronomy.org",51234)
    agent.user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    puts "fetching #{url} ... "
    agent.get('http://www.ticketmaster.com') # tkmstr checks this now - you must request a real url first.
  
  return fetch_url(agent,url,5)
  end


  def fetch_parse_and_save(fast_forward=false)
    initialize_cache    
#    don't parse venues that don't have shows more than once a month
#    puts "last_crawled_at: #{last_crawled_at}"
#    puts "events_last_imported: #{events_last_imported}"
#    puts ">30 days since last crawl? #{last_crawled_at+30.days<Time.now}"
    if events_last_imported==0
      if last_crawled_at and last_crawled_at+30.days>Time.now
        puts "low-activity club, skipping ... "
        return 
      end
    end
    page,cached = fetch
    if cached and fast_forward
      puts "cached, fast-forwarding ..."
      return nil
    end
    total_events = parse_and_save_page(page)
    self.events_last_imported=total_events
    self.last_crawled_at=Time.now
    self.save
  end

=begin

| 684614 | 2010-03-24 04:19:28 | The New Pornographers                                                      | 2010-03-26 12:00:00 | 2010-06-19 19:00:00 | 
| 686196 | 2010-03-24 07:38:46 | The New Pornographers                                                      | 2010-03-28 10:00:00 | 2010-07-18 19:30:00 | 
| 685476 | 2010-03-24 06:06:49 | The New Pornographers                                                      | 2010-03-26 10:00:00 | 2010-06-13 18:00:00 | 
| 685686 | 2010-03-24 06:24:53 | The New Pornographers Moonrise Hotel Package                               | 2010-03-26 17:00:00 | 2010-06-28 20:00:00 | 
| 685358 | 2010-03-24 05:49:26 | The New Pornographers with the Dodos & the Dutchess and the Duke           | 2010-03-26 10:00:00 | 2010-06-27 20:00:00 | 


{"responseHeader":{"status":0
,"QTime":3}

,"response":{"facet_counts":{}

,"numFound":13

,"docs":[

{"VenueSEOLink":"/The-Loft-tickets-Dallas/venue/99043"
,"VenueId":"99043"
,"MusicBrowseGenre":["All Music"
,"More Concerts"]
,"LocalEventMonthYear":"January 2009"
,"PostProcessedData":{"SuppressWireless":true
,"Onsales":{"unmodified_epdate":null
,"expire":"Sat, 01/31/09<br>08:30 PM"
,"onsales":[{"suppress":0
,"onsale_type":1
,"interval":{"end":"Sat, 01/31/09<br>08:30 PM"
,"start":"Sun, 01/18/09<br>10:00 AM"}}]
,"event_date":{"event_date_type":5
,"date":"Sat, 01/31/09<br>08:30 PM"
,"date_range":null
,"suppress_time":0}
,"onsale_status":"1"}}
,"VenueCity":"Dallas"
,"MajorGenreId":[10001]
,"ExpirationDate":null
,"VenueCityState":"Dallas, TX"
,"Type":["Event"]
,"AttractionSEOLink":["/Spazmatics-tickets/artist/834846"]
,"EventType":0
,"EventName":"Spazmatics"
,"AttractionId":["834846"]
,"LangCode":"en-us"
,"AttractionName":["Spazmatics"]
,"OnsaleOn":"2009-01-18T16:00:00Z"
,"DMAId":[212,218,261,326,386,405,415]
,"AttractionImage":[""]
,"MinorGenreId":[52]
,"LocalEventWeekdayString":"Saturday"
,"Host":"DAL"
,"EventDate":"2009-02-01T02:30:00Z"
,"LocalEventDateDisplay":"Sat, 01/31/09<br>08:30 PM"
,"LocalEventDay":31
,"Timezone":"America/Chicago"
,"LocalEventYear":2009
,"MinorGenre":["More Concerts"]
,"timestamp":"2009-01-31T10:12:08.982Z"
,"DocumentId":"Event+0C00422608B9E449+en-us+1"
,"LocalEventMonth":1
,"VenueName":"The Loft"
,"Id":"0C00422608B9E449"
,"Genre":["More Concerts"]
,"VenueCountry":"US"
,"MajorGenre":["Music"]
,"VenueState":"TX"
,"EventId":"0C00422608B9E449"
,"OnsaleOff":null
,"search-en":"Spazmatics Dallas TX  Texas The Loft January 2009 Saturday 75215 More Concerts"},
=end

  def calculate_sale_dates(doc)
=begin
    "Onsales":
    {
      "unmodified_epdate":null
      "expire":"Sat, 01/31/09<br>08:30 PM"
      "onsales":
        [
          {
          "suppress":0
          "onsale_type":1
          "interval":
            {
              "end":"Sat, 01/31/09<br>08:30 PM"
              "start":"Sun, 01/18/09<br>10:00 AM"
            }
          }
        ]
    "event_date":
      {
        "event_date_type":5
        "date":"Sat, 01/31/09<br>08:30 PM"
        "date_range":null
        "suppress_time":0
      }
    "onsale_status":"1"
    }
    }
=end

    onsales = doc['PostProcessedData']['Onsales']['onsales']
    presale_date=nil
    onsale_date=nil
    onsales.each{|onsale|
        type=onsale['onsale_type']
        date=onsale['interval']['start']
        onsale_date=date if type=='1'
        presale_date=date if type=='2'
      }
    return onsale_date,presale_date
  end

  def parse_onsale_date(s)
    # Fri, 03/26/10<br>10:00 AM
    x = s.split(",")
    y = x[1]
    z = x.split("<br>").first
    date_triplet = z.split("/")
    date = DateTime.now
    date.day = date_triplet[0]
    date.month = date_triplet[1]
    date.year = date_triplet[2]
    time_triplet = x.split("<br>")[1]
    b = time_triplet.split(/:\s/)
    date.hour = b[0]
    date.minute = b[1]
    date.hour=(date.hour.to_i+12).to_s if b[2]=~/pm/i
    puts date.inspect
  end

  def parse_and_save_page(page)
    json = JSON.parse(page)
    # get docs hash element - it is an array of hashes - each array element representing a show, with hash elements being the show data and metadata
    
    num_found = json['response']['numFound'].to_i rescue 0
    puts "found #{num_found}"
    docs = json['response']['docs']
    return unless docs
    docs.each{|doc|
      begin
        event_name = doc['EventName']
        uid = doc['Id']
        attraction_id = doc['AttractionId']
        # url format: http://www.ticketmaster.com/event/0C00422608B9E449?artistid=834846&majorcatid=10001&minorcatid=52
        major_genre_id = doc['MajorGenreId']
        minor_genre_id = doc['MinorGenreId']
        onsale_date, presale_date=calculate_sale_dates(doc)
        url = "http://www.ticketmaster.com/event/#{uid}?artistid=#{attraction_id}&majorcatid=#{major_genre_id}&minorcatid=#{minor_genre_id}"
        date_string = doc['LocalEventDateDisplay'].sub("<br>"," ")
        event  =  ImportedEvent.find_by_uid(uid)
        if not event
          event = ImportedEvent.new 
          event.status='new'
          event.cancelled='no'
        end
        if date_string=="cancelled"
          event.cancelled="yes" # preserve previous time if the show is now cancelled
        else
          time = Time.parse(date_string)
          # only set time if it's not cancelled
        end
        # does this event already exist? if not, create it. if so, update existing record.
        event.uid=uid
        event.date=time
        event.venue_id=self.id
        event.url=url
        event.body=event_name
        event.artist_id=attraction_id
        event.major_cat_id=major_genre_id
        event.minor_cat_id=minor_genre_id
        event.onsale_date=onsale_date
        event.presale_date=presale_date
        event.source='ticketmaster'
        event.level='primary'
        event.save
        puts "#{event.date} #{event_name} #{uid} [onsale: #{event.onsale_date}] [presale: #{event.presale_date||'.'}]"
      rescue => e
        puts "ERROR. CAN'T PARSE, SKIPPING ... (#{e})"
      end
    }
    return num_found
  end

  def parse_and_save_page_(page)
    doc = Hpricot(page)
    # find all 
    times=Array.new
    (doc/"span.tableListing-date").each{|node|
      datetime_string = node.inner_html
      datetime_string.gsub!("<br>"," ")
      if datetime_string=~/cancel/i
        time="cancelled" 
      else
        time = Time.parse(datetime_string)
      end
      times<<time
    }
    (doc/"span.tableListing-act").each_with_index{|node,i|
      begin
        artist_name = (node/"a").first.inner_html
        event_url = (node/"a").first.attributes['href']
        uid = event_url.scan(/event\/(.+?)\?/)[0][0] rescue Digest::MD5.hexdigest(event_url)
        artistid=event_url.scan(/artistid\=(.+?)\&/)[0][0] rescue -1
        majorcatid=event_url.scan(/majorcatid\=(.+?)\&/)[0][0] rescue -1
        minorcatid=event_url.scan(/minorcatid\=(.+?)/)[0][0] rescue -1
        event  =  ImportedEvent.find_by_uid(uid)
        if not event
          event = ImportedEvent.new 
          event.status='new'
          event.cancelled='no'
        end
        if times[i]=="cancelled"
          event.cancelled="yes" # preserve previous time if the show is now cancelled
        else
          time = times[i].to_s # only set time if it's not cancelled
        end
        # does this event already exist? if not, create it. if so, update existing record.
        event.uid=uid
        event.date=times[i]
        event.venue_id=self.id
        event.url=event_url
        event.body=artist_name
        event.artist_id=artistid
        event.major_cat_id=majorcatid
        event.minor_cat_id=minorcatid
        event.source='ticketmaster'
        event.level='primary'
        event.save
        puts "#{time} #{artist_name} #{uid} #{majorcatid} #{minorcatid}"
      rescue 
        puts "ERROR. CAN'T PARSE, SKIPPING ..."
      end
    }
  end

end
