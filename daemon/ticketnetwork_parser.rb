#require "../app/models/imported_events.rb"
#require "../app/models/shared_events.rb"

require 'rubygems'
require 'mechanize'
require 'digest/md5'
require "../app/models/venue.rb"
require "../app/models/ticketmaster_venue.rb"
require "../app/models/import_parser.rb"

class TicketnetworkParser < ImportParser
  include FileUtils
  
  def initialize_crawl_agent
    agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
    agent.user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    agent
  end


  def crawl(code=nil,fast_forward=false)
    @affiliate_id="1944"
    agent = initialize_crawl_agent
    states = ["California","Texas","New York","Florida","Illinois","Pennsylvania","Ohio","Michigan","Georgia","North Carolina","New Jersey","Virginia","Washington","Massachusetts","Indiana","Arizona","Tennessee","Missouri","Maryland","Wisconsin","Minnesota","Colorado","Alabama","South Carolina","Louisiana","Kentucky","Puerto Rico","Oregon","Oklahoma","Connecticut","Iowa","Mississippi","Arkansas","Kansas","Utah","Nevada","New Mexico","West Virginia","Nebraska","Idaho","Maine","New Hampshire","Hawaii","Rhode Island","Montana","Delaware","South Dakota","Alaska","North Dakota","Vermont","Washington DC","Wyoming"]

    states.each{|state|
      puts state
      url="http://www.ticketnetwork.com/ticket/#{state.downcase}-events.aspx"
      begin
        parse_state_url(agent,url,fast_forward)
      rescue TimeoutError
        puts "error parsing #{state}."
      rescue Exception
        puts "error parsing #{state}."
      end
      #break
    }
  end

=begin
<tr class="resultsGen(Odd|Even)Row">
  <td>
    <a href="/ticket/bobby-mcferrin-events.aspx"><b>Bobby Mcferrin</b></a>
  </td>
  <td>
    <b>06/01/2008</b><br />Sun 8:00PM
  </td>
  <td>
    <a href="/ticket/kennedy-center-concert-hall-events.aspx"><b>Kennedy Center - Concert Hall</b></a><br />
    <a href="/ticket/washington-events.aspx">Washington</a>, DC
  </td>
  <td class="viewTix">
    <a href="/tix/bobby-mcferrin-tickets-june-1-2008-washington-dc-772189.aspx" title="Bobby Mcferrin tickets">View Tickets</a>
  </td>
</tr>
=end
  def process_location(location)
    ret = Array.new
    location.split(",").each{|elem|
      next if elem=~/\(/
      ret<<elem.strip
    }
    ret
  end

  def parse_state_url(agent,url,fast_forward=false)
    puts "fetching #{url}..."
    body,cached = fetch_url(agent,url,30)
    if cached and fast_forward
      puts "... cached, fast-forwarding"
      return
    end
    doc = Hpricot(body)
    odds = (doc/"tr.resultsGenOddRow")
    evens = (doc/"tr.resultsGenEvenRow")
    trs = odds + evens
#    uid = event_url.scan(/event\/(.+?)\?/)[0][0] rescue Digest::MD5.hexdigest(event_url)

    trs.each_with_index{|tr,i|
      begin
        tds = (tr/"td")
        artist_name = strip_tags tds[0].inner_html
        datetime_string = strip_tags tds[1].inner_html
        location = strip_tags(tds[2].inner_html,", ")
        url = (tds[3]/"a").first.attributes['href']
        url = "http://www.ticketnetwork.com#{url}?kbid=#{@affiliate_id}"
        #puts "artist_name: #{artist_name}"
        #puts "datetime_string: #{datetime_string}"
        #puts "location: #{location}"
        #puts "url: #{url}"
        uid = url.scan(/\-(\d+)\.aspx/)[0] rescue Digest::MD5.hexdigest(url)
        uid=uid.to_s
        venue_name,venue_city,venue_state = process_location(location)
        venue=Venue.find_by_name_and_state(venue_name,venue_state)
        venue=Venue.find_by_name_and_state("the #{venue_name}",venue_state) if not venue
        venue=Venue.find_by_name_and_state(venue_name.sub(/^the\s/i,"").strip,venue_state) if not venue
        if not venue
          if venue_name.strip.empty? or venue_city.strip.empty? or venue_state.strip.empty?
            puts "venue data missing, skipping..."
            next
          end            
          venue=Venue.new
          venue.name=venue_name
          venue.city=venue_city
          venue.state=venue_state
          venue.source="ticketnetwork"
          venue.save
          puts "added venue #{venue_name}."
        else
          #puts "already added venue #{venue_name}, not adding again."
        end
        verb="modified"
        ie  =  ImportedEvent.find_by_uid(uid)
        if not ie
          verb="added"
          ie = ImportedEvent.new 
          ie.status='new'
          ie.cancelled='no'
        end
        ie.uid=uid
        ie.date=DateTime.parse(datetime_string)
#        ie.time=Time.parse(tokens[8])
        ie.venue_id=venue.id
        ie.venue_name=venue.name
        ie.url= url
        ie.body = artist_name
        ie.cancelled='no'
        ie.status='new'
        ie.source='ticketnetwork'
        ie.level='secondary'
        ie.save
        puts "+++ [#{i}/#{trs.size}] #{verb} event #{ie.body} on #{ie.time} at #{venue.name}."        
      rescue =>e
        puts e.to_s
        next
      end
        
    }
  end
  
  def extract_ticket_offers(url,fast_forward)
#    puts "fetching #{url}..."
    body,cached = fetch_url_cached(url,7)
    if cached and fast_forward
      puts "... cached, fast-forwarding"
      return
    end
    ticket_offers=Array.new
    doc = Hpricot(body)
    even_trs = (doc/"tr.resultsTicEvenRow")
    odd_trs = (doc/"tr.resultsTicOddRow")
    trs = even_trs + odd_trs
    trs.each{|tr|
      tds = (tr/:td)
      children = tds[0].children
      section = strip_tags(children[1].to_s)
      row = strip_tags(children[3].to_s )
      price_string = tds[1].inner_html
      price = price_string.scan(/[\d.]+/).first
      quantity_td = tds[3]
      quantity = ((quantity_td/:select)/:option)[0].inner_html
      to = TicketOffer.new
      to.section = section
      to.row =row
      to.price=price
      to.quantity=quantity
      ticket_offers<<to
    }
    return ticket_offers
  end
  
  
end
