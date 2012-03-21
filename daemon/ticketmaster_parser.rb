#require "../app/models/imported_events.rb"
#require "../app/models/shared_events.rb"

require 'rubygems'
require 'mechanize'
require "../app/models/venue.rb"
require "ticketmaster_venue.rb"
require "import_parser.rb"

class TicketmasterParser < ImportParser
  

  def find_valid_urls
    @url_specifier="ticketmaster.com/venue"
    @domain="ticketmaster.com"
    phrase_base="find+tickets"
    states = %w{ AL AK AS AZ AR CA CO CT DE DC FM FL GA GU HI ID IL IN IA KS KY LA ME MH MD MA MI MN MS MO MT NE NV NH NJ NM NY NC ND MP OH OK OR PW PA PR RI SC SD TN TX UT VT VI VA WA WV WI WY}
    states.each{|state|
      puts state
      @phrase="%22#{phrase_base}%22+#{state}" 
      super
    }
  end


# product_code|product_name|brand_name|level1|level2|level3|level4|level5|mapped_cat_level1|mapped_cat_level2|
# mapped_cat_id|description|buyat_short_deeplink_url|old_style_deeplink_url|image_url|image_url_2|currency|online_price|
# offline_price|recurring_charge|old_price|delivery_cost|delivery_time|availability|promotion_text|best_seller|warranty|
# condition|offer_type|manufacturer_code|keywords|location|duration|date_from|date_to|City|State|Street|ZipCode|fieldE|
# fieldF|fieldG|fieldH|fieldI|fieldJ|fieldK|fieldL|fieldM|fieldN|fieldO|fieldP|fieldQ|fieldR|fieldT|fieldU|fieldV|fieldW|
# fieldX|fieldY|fieldZ

#106642|Ed Smith Stadium||FL|||||||||http://ticketsus.at/tourfilter/106642.html|
#http://ticketsus.at/tourfilter?CTY=9&DURL=http%3A%2F%2Fwww.ticketmaster.com%2Fvenue%2F106642%3Fcamefrom%3D%26brand%3Dtm|
#https://ce.imgc.perfb.com/imagehelper/displayImage.php?ID=112998816||USD|||||||||||||||||||
#Sarasota|FL|2700 12th Street|34237|||||||||||||||||||||

# 0 code
# 1 name
# 3 state
# 12 url_1
# 13 url_2
# 35 city
# 36 state
# 37 Address 1
# 38 zip code
  
  def import_venues_from_file(country_code,file_name)
    f = File.open(file_name, 'r')  
    text = f.read  
    lines = text.split(/$/) 
    lines.each{|line|
      begin
        tokens = line.split("|")
        code = tokens[0].strip
        venue = Venue.find_by_code(code)
        venue ||= Venue.new
        venue.code=code
        venue.name=tokens[1].strip
        venue.affiliate_url_1=tokens[12].strip
        venue.affiliate_url_2=tokens[13].strip
        venue.logo_url=tokens[14].strip
        venue.city=tokens[35].strip
        venue.state=tokens[36].strip
        venue.address=tokens[37].strip
        venue.zipcode=tokens[38].strip
        venue.url="http://www.ticketmaster.com/json/search/event?vid=#{code}"
        venue.source="ticketmaster"
        venue.save
        puts "#{venue.code} #{venue.name} in #{venue.city}, #{venue.state}"
      rescue
      end
    }
    f.close
  end
  
  def crawl(code=nil,fast_forward=false)
#      venue=Venue.find_by_code(8321)
#      venue=TicketmasterVenue.find_by_code(237569)
    if code 
      venues=[TicketmasterVenue.find_by_code(code)]
      puts "loaded one venue: #{@code} #{venues[0].name}"
    else
      venues = TicketmasterVenue.find_all_by_source("ticketmaster")
      puts "loaded #{venues.size} venues."
    end
    total = venues.size
    venues.each_with_index{|venue,i|
      begin
        next if venue.code=="product_code"
        header("fetching, parsing and saving events for #{venue.name.downcase} (#{i} of #{total})")
        venue.fetch_parse_and_save(fast_forward)
      rescue TimeoutError
        puts "+++ timed out: #{venue.id}"
      rescue => e
        puts e
      end
    }
    # fetch each url and parse out times and dates
  end

# ------------------------------------------------------------------------------------
# ------------------------------------------------------------------------------------
#     ticket offer parsing
#

def extract_ticket_offers_old(url,fast_forward)
#  puts "fetching #{url}..."
  begin
    body,cached = fetch_url_cached(url,7)
    if cached and fast_forward
      puts "... cached, fast-forwarding"
      return
    end
    start_index=body.index("Event Details")
    return [] unless start_index
    price_area = body[start_index..(start_index+10000)]
    matches = price_area.scan(/\$([\d.])+/)
    return nil if matches.nil?
    price = matches[0][0]
    if price
      return [price]
    else
      return nil
    end
  rescue
    return nil
  end
end

def extract_ticket_offers_ticketweb(body)
#  puts "processing ticketweb page ... "
  start_index=body.index("Type of Ticket")
  if start_index
    price_area = body[start_index..(start_index+1000)]
  else
    price_area = body
  end
  matches = price_area.scan(/\$(\d+)/)
  ticket_offers = Array.new
  matches.each{|match|
    begin
#      puts "price (r): #{match.first}"
      ticket_offers<<match.first
    rescue
      puts "#error: #{tr.inner_html}"
    end
  }
  ticket_offers
end

def extract_ticket_offers(url,fast_forward)
#  puts "fetching #{url}..."
  body,cached = fetch_url_cached(url,7)
  if cached and fast_forward
    puts "... cached, fast-forwarding"
    return
  end
  return extract_ticket_offers_ticketweb(body) if body.scan("ticketweb").size>5
  doc = Hpricot(body)
  div = (doc/"div.container-neutralZone")
  h4s  = (div/"h4")
  ticket_offers = Array.new
  h4s.each{|h4|
    spans = (h4/"span.allCaps")
    span = spans.first
    if span
      begin
        section = span.inner_html
        price_string = h4.next_node.to_s
        price = price_string.scan(/[\d.]+/).first
        to = TicketOffer.new
        to.section=section
        to.price=price
        ticket_offers<<to
      #rescue
      end
    end
  }
  if ticket_offers.empty? 
#    puts "no tickets found via DOM, trying RegExp..."
    return extract_ticket_offers_old(url,fast_forward)
  else 
    return ticket_offers
  end
end

end

# different ticketmaster offer formats:
# <h4><span class="allCaps"></span></h4>US $35.00 - US $150.00<br><br>  
# <h4><span class="allCaps">RIGHT SECTION</span></h4>US $30.00<br><br>             <h4><span class="allCaps">LEFT SECTION</span></h4>US $30.00<br><br>


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
