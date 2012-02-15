


# process for importing ticketmaster events 
# 1. import venue data from feed (periodically, manually):
# =>  download file from buy.at
# =>  ruby import_events_daemon.rb import_ticketmaster_us_venues <filename>
# =>  loops through pipe-delimited file, updates any pre-existing venues, adds new ones, marks last_updated for all
# =>  deletes any venues with last_updated<today + no events
# =>  (create url from id)

# 2. crawl venues (daily)
# =>  loop through all venues
# =>  if no events, don't crawl unless last_crawled is null or greater than a month ago
# =>  if events, fetch page 1.
# =>  determine number of pages
# =>  for each page, get all events
# =>    for each event
# =>      does it exist (based on unique event identifier)? if not:
# =>        save artist name, tm artist id, majorcatid,minorcatid, date, time,url,unique event identifier

require 'rubygems'
require 'mechanize'
require "../app/models/venue.rb"
require "../app/models/ticketmaster_venue.rb"
require "../app/models/import_parser.rb"

class StubhubParser < ImportParser
  include FileUtils

FEED_URL="http://www.stubhub-feeds.com/datafeeds/Full_Affiliate_Feed_CJ.txt"
CJ_PID="2904311"
#AFFILIATE_ID="8029"

def header (s)
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end

# Product URL,CITY,DESCRIPTION,EVENTDATE,EVENTDAY,EVENTMONTH,EVENTMONTH2,EVENTYEAR,EVENTZTIME,
# GENRE,GENREGRANDPARENT,GENREPARENT,ID,IMAGE_URL,REGION,STATE,VENCONFIG,VENUE,VENUE_ID,ZIP
# http://www.stubhub.com/?ticket_finder=XXXX&event_id=588743,Vancouver,Cat Power Tickets,
# 4/10/2008,10,4,April,2008,19:30,Cat Power Tickets,Concert Tickets,Artists A - C,588743,
# http://www.stubhub.com/data/venue_maps/10343/,Vancouver,BC,concert,
# Vogue Theatre - Vancouver,10343,V6Z1L2
# 0 - url
# 1 - city
# 2 - description
# 3 - eventdate
# 8 - event time
# 9 - genre
# 10 - genre grandparent
# 11 - genre parent
# 12 - id
# 13 - image_url
# 14 - city/region
# 15 - state
# 16 - venue config
# 17 - venue name
# 18 - venue id
# 19 - zip code

  def process_name(name)
    name.strip!
    name.sub! /[-(].+$/,""
    name.strip
  end
  
  def process_url(url)
    url.sub("<pid>",CJ_PID)
  end
  
  def process_description(description)
    description.strip.gsub(/tickets/i,"").strip
  end

# Product URL,CITY,DESCRIPTION,EVENTDATE,EVENTDAY,EVENTMONTH,EVENTMONTH2,EVENTYEAR,EVENTZTIME,
# GENRE,GENREGRANDPARENT,GENREPARENT,ID,IMAGE_URL,REGION,STATE,VENCONFIG,VENUE,VENUE_ID,ZIP
# http://www.stubhub.com/?ticket_finder=XXXX&event_id=588743,Vancouver,Cat Power Tickets,
# 4/10/2008,10,4,April,2008,19:30,Cat Power Tickets,Concert Tickets,Artists A - C,588743,
# http://www.stubhub.com/data/venue_maps/10343/,Vancouver,BC,concert,
# Vogue Theatre - Vancouver,10343,V6Z1L2
# 0 - url
# 1 - city
# 2 - description
# 3 - eventdate
# 8 - event time
# 9 - genre
# 10 - genre grandparent
# 11 - genre parent
# 12 - id
# 13 - image_url
# 14 - city/region
# 15 - state
# 16 - venue config
# 17 - venue name
# 18 - venue tid
# 19 - zip code
  
  def crawl(code=nil,fast_forward=false)
    # first download tab-delimited file
    url = FEED_URL
    puts "fetching #{url}..."
    text = fetch_url_cached(url)
    puts "downloaded #{text.size} bytes, parsing now ..."
    lines = text.split(/$/) 
    puts "#{lines.size} lines."
    num_processed=0
    artists=Hash.new
    num_lines=lines.size
    lines.each_with_index{|line,i|
        next if line=~/EVENTZTIME/
      begin
#        puts line
        tokens = line.split("\t")
        if tokens[10]!~/concert tickets/i
#        if tokens[10]!~/concert tickets|music/i
#          puts "skipping, invalid line (no 'concert tickets') [#{tokens[10]}]..."
          next
        end
        num_processed+=1
        # create venue row if not already created
        # create imported_event row if not already created
        id = tokens[12]
        uid="stubhub_#{id}"
        venue_name = process_name(tokens[17])
        venue_state = tokens[15]
        venue_city = tokens[14]
        venue_zipcode = tokens[19]
        venue_id = tokens[18]
        venue=Venue.find_by_name_and_state(venue_name,venue_state)
        venue=Venue.find_by_name_and_state("the #{venue_name}",venue_state) if not venue
        venue=Venue.find_by_name_and_state(venue_name.sub(/^the\s/i,"").strip,venue_state) if not venue
        if not venue
          venue=Venue.new
          venue.name=venue_name
          venue.city=venue_city
          venue.state=venue_state
#          venue.zipcode=venue_zipcode.strip
          venue.source="stubhub"
          venue.code = venue_id
          venue.save
          puts "added venue #{venue_name}."
        else
#          puts "already added venue #{venue_name}, not adding again."
        end
#        if ImportedEvent.find_by_uid(uid)
        body = process_description(tokens[2])
        date = Time.parse("#{tokens[3]} #{tokens[8]}")
        ie = ImportedEvent.find_by_source_and_body_and_date_and_venue_id("stubhub",body,date,venue.id)
        if ie
          puts "[#{i}/#{num_lines}] already added event (#{body}), modifying ..."
          #next
        else
          ie = ImportedEvent.new
          ie.status='new'
        end
        ie.uid=uid
        ie.date=date
        ie.time=Time.parse(tokens[8])
        ie.venue_id=venue.id
        ie.venue_name=venue.name
        ie.url= process_url(tokens[0]).strip
        ie.body = body
        ie.cancelled='no'
        ie.source='stubhub'
        ie.level='secondary'
        ie.save
        puts "+++ [#{i}/#{num_lines}] added event #{ie.body} on #{ie.time} at #{venue.name}."
      rescue
        puts "#error"
      end
      }
  end

  def crawl_old(code=nil,fast_forward=false)
    # first delete all stubhub entries
    puts "deleting all stubhub ticket entries ..."
    SecondaryTicket.delete_all("seller='stubhub'")
    # first download tab-delimited file
    url = "http://www.stubhub-feeds.com/datafeeds/Full_Affiliate_Feed.txt"
    puts "fetching #{url}..."
    text = fetch_url_cached(url)
    puts "downloaded #{text.size} bytes, parsing now ..."
    lines = text.split(/$/) 
    puts "#{lines.size} lines."
    num_processed=0
    artists=Hash.new
    lines.each{|line|
        next if line=~/EVENTZTIME/
#      begin
#        puts line
        tokens = line.split("\t")
        next unless tokens[10]=~/concert tickets/i
        num_processed+=1
        st = SecondaryTicket.new
        st.body=process_description(tokens[2])
        st.seller="stubhub"
        search_term=st.body.gsub " ","+"
        search_term=search_term.sub(/\(.+$/,"").strip
        st.url="http://www.stubhub.com/search/doSearch?start=0&rows=50&searchStr=#{search_term}&ticket_finder=#{AFFILIATE_ID}"
        begin
          st.save
        rescue
          next
        end
        artists[st.body]=true
        puts "[#{st.body}] #{st.url}"
#      rescue
#     end
    }
    puts "done. processed #{num_processed} concerts out of #{lines.size} total events. #{artists.size} unique artists.  "
    
  end
  
  

# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
#     ticket offer parsing
#

def extract_ticket_offers(url,fast_forward)
#  puts "fetching #{url}..."
  body,cached = fetch_url_cached(url,7)
  if cached and fast_forward
    puts "... cached, fast-forwarding"
    return
  end
  # <table id='tt'><tr><td class="ttsc"><span onmouseover="sh_t_shs( '155115');">Upper 204</span></td><td class="ttrc">O</td>
  # <td>Up to 8</td><td class="ttpc">$92.00 <span class="e">each</span></td><td class="tttc">
  # <a href="?ticket_id=132515203" title="View Details">View Details</a></td></tr>
  doc = Hpricot(body)
  table = (doc/"table#tt")
  trs  = (table/"tr")
  ticket_offers = Array.new
  trs.each{|tr|
    begin
      tds = (tr/"td")
      section = strip_tags(tds[0].inner_html)
      row =  tds[1].inner_html
      quantity_string = tds[2].inner_html
      price_string = strip_tags(tds[3].inner_html)
      price_string.gsub!(",","")
      price = price_string.scan(/\d+/).first
      quantity=quantity_string.scan(/\d+/).first
      to = TicketOffer.new
      to.section=section
      to.row = row
      to.quantity=quantity
      to.price=price
#      puts "#{section}/#{row}: #{quantity} @ $#{price}"
      ticket_offers<<to
    rescue
      puts "#error"
    end
  }
  ticket_offers
end

end

