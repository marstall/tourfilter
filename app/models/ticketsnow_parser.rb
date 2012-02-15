require 'ticketsnow_city_codes.rb'


require 'rubygems'
require 'mechanize'
require 'digest/md5'
require "../app/models/import_parser.rb"

class TicketsnowParser < ImportParser
  include FileUtils
  
  def initialize_crawl_agent
    agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
    agent.user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    agent
  end


  def generate_urls(code)
    urls = Array.new
    time = Time.new
    0.upto(2) {|i|
      url = "http://www.ticketsnow.com/EventCalendar/EventsCalendar.aspx?MAID=#{code}&IYR0UT4VY=1&date=#{time.month}/01/#{time.year}"
      time=time+1.month
      urls<<[url,time.year]
    }
    urls
  end

  def crawl(code=nil,fast_forward=false)
    @affiliate_id="13119"
    agent = initialize_crawl_agent
    TICKETSNOW_CITY_CODES.split(/^/).collect{|line|
      elems = line.scan(/[^:,]+/)
      code = elems[0].strip
      city = elems[1].strip
      state = elems[2].strip
      urls = generate_urls(code)
      urls.each{|_url|
      begin
        url = _url.first
        year = _url.last
        parse_city_month_url(agent,url,year,city,state,fast_forward)
#      rescue TimeoutError
#        puts "error parsing #{city}/#{state}."
#      rescue Exception
#        puts "error parsing #{city}/#{state}."
      end
      }
    }
  end

=begin
<td class="dayCellOtherMonth">
<div class="date">17 - August</div>
<div class="entry">
<img  style="border-style: none" src="http://content.ticketsnow.com/graphics/miscellaneous/icon-bday.gif"  /><a href="javascript:openBiosPage('http://www.ticketsnow.com/CelebrityBiographies/CelebrityBiographies.aspx?preview=false&CelebrityBiographyDate=8/17/2008&PopUp=true');" class="birthday">Today's Birthdays</a></div>
<div class="entry">
<a href="http://www.ticketsnow.com/TicketsList.aspx?PID=632659" title="7:30P - Toby Keith (Comcast Center - MA)" class="specificCategoryLinkConcerts">Toby Keith (Comcast Center - MA)</a></div>
<div class="entry">
<a href="http://www.ticketsnow.com/TicketsList.aspx?PID=645797" title="8:00P - Puddle of Mudd (Hampton Beach Casino Ballroom)" class="specificCategoryLinkConcerts">Puddle of Mudd (Hampton Beach Casino Ballroom)</a></div>
<div class="entry">
<a href="http://www.ticketsnow.com/TicketsList.aspx?PID=632252" title="TBD -  George Thorogood (Bank of America Pavilion)" class="specificCategoryLinkConcerts">George Thorogood (Bank of America Pavilion)</a></div>
<div>&nbsp;</div>
<div>&nbsp;</div>
<div>&nbsp;</div>
</td>
=end

  def parse_city_month_url(agent,url,year,city,state,fast_forward=false)
    puts "fetching #{url}..."
    body,cached = fetch_url(agent,url,30)
    if cached and fast_forward
      puts "... cached, fast-forwarding"
      return
    end
    doc = Hpricot(body)
    tds = (doc/"td.dayCellOtherMonth")
    tds.each_with_index{|td,i|
      date_string = (td/"div.date").inner_html
      elems = date_string.split(" - ")
      day = elems.first
      month = elems.last
      (td/"a").each{|a|

        # extract meat of listing
        body = a.inner_html
        title = a.attributes['title']
        href = a.attributes['href']

        # make sure this is a proper listing
        next unless href=~/TicketsList\.aspx/

        # get url
        url = href
        
        # get time
        time_string = title.split(" - ").first.strip
        datetime_string = "#{month} #{day}, #{year} #{time_string}"
        datetime = DateTime.parse(datetime_string)
        # get venue name
        venue_name = body.scan(/\((.+?)\)/).first.first

        # get artist name
        artist_name = body.scan(/(.+?)\(/).first

        # get uid
        uid = "ticketsnow_#{url.scan(/\=(\d+)$/)[0][0] rescue Digest::MD5.hexdigest(url)}"
        # add venue
        venue = Venue.add_or_find(venue_name,city,state,"ticketsnow")
        url = "#{url}&id=13119"
        # add imported_event
        _ie,verb = add_imported_event(uid,datetime_string,venue,artist_name.to_s,url,'ticketsnow','primary')

        puts "+++ #{verb} event #{_ie.body} on #{_ie.date.month}/#{_ie.date.day} at #{venue.name} (#{city}, #{state})."        
     }
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
    trs = (doc/"tr.inventoryRow")
#    puts "trs: #{trs.size}"
    return unless trs
    trs.each{|tr|
      tds = (tr/:td)
      section = tds[1].inner_html
      row = tds[2].inner_html
      price_string = (tds[4]/:span).inner_html
      price = price_string.scan(/[\d.]+/).first
      next if price.nil? or price.to_f<1
      quantity_td = tds[6]
      quantity = (quantity_td/"div.quantityAmount").inner_html
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
