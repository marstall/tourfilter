require "../app/models/parser.rb"

class CoolidgeParser < Parser

  def parse_page(page)
    # get the film precis listings, extract metadata:title,date, ticket buying link
    # fetch detail page for each, extract synopsis, photo, showtime
    return unless page.raw_body
    doc = Hpricot(page.raw_body[0..65000])
    (doc/"p.day").each{|p|
      date_string = clean( (p/"span.date").inner_html)
      (p/"dl.movie-by-day").each{|dl|
        h = Hash.new
        h[:date_string]=date_string
        process_meta_block(dl,h)
        Showing.add_new_by_hash(page,h)
      }
    }
  end
  
  def process_meta_block(dl,h)
    h[:title] = initial_capsify((dl/"h5").inner_html.gsub(/\:$/,"").downcase)
    h[:detail_link] = (dl/"a").first.attributes['href'] rescue nil
    h[:detail_link] = nil unless h[:detail_link]=~/coolidge/
    h[:showtime_string] = process_times(dl)
    process_detail_page(h[:detail_link],h)
    
  end  

  def process_times(dl)
    times=Array.new
    (dl/"span.time > a").each{|a|
      times<<a.inner_html
    }
    times.join(" ")
  end

  def process_detail_page(url,h)
    doc = fetch_hpricot(url) if url
    return unless doc
    # parse description
    # parse image url
    
    h[:synopsis]=(doc/"div.itemtext").first.inner_html rescue nil
    h[:image_url]=(doc/"img").first.attributes['src'] rescue nil
  end
end

=begin
   <p class="day">
      <hr class="hr-side">
      <h7><span class="date" title="09092007">
          <b>Sun</b> Sep 09, 2007 </span></h7>

      <dl class="movie-by-day">
        <dt>
          <h5>BECOMING JANE:</h5>
          <small><span class="length">
          (
    2hr 10mins
    )
   
    <a href="http://www.coolidge.org/becomingjane">description</a>
            </span>
          </small>

          <br>
        </dt><span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=BECOMING+JANE,090920071200,3,130,">12:00PM
            </a>
          <sup>3</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=BECOMING+JANE,090920071420,3,130,">2:20PM
            </a>
          <sup>3</sup>

        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=BECOMING+JANE,090920071645,3,130,">4:45PM
            </a>
          <sup>3</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=BECOMING+JANE,090920071915,3,130,">7:15PM
            </a>
          <sup>3</sup>

        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=BECOMING+JANE,090920072140,3,130,">9:40PM
            </a>
          <sup>3</sup>
        </span>
        <p></p>
      </dl>
      <dl class="movie-by-day">

        <dt>
          <h5>PARIS JE TAIME:</h5>
          <small><span class="length">
          (
    2hr 5mins
    )
   
    </span></small>
          <br>
        </dt><span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=PARIS+JE+TAIME,090920071200,4,130,">12:00PM
            </a>

          <sup>4</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=PARIS+JE+TAIME,090920071415,4,130,">2:15PM
            </a>
          <sup>4</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=PARIS+JE+TAIME,090920071645,4,130,">4:45PM
            </a>

          <sup>4</sup>
        </span>
        <p></p>
      </dl>
      <dl class="movie-by-day">
        <dt>
          <h5>2 DAYS IN PARIS:</h5>
          <small><span class="length">

          (
    1hr 40mins
    )
   
    <a href="http://www.coolidge.org/node/1036">description</a>
            </span>
          </small>
          <br>
        </dt><span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=2+DAYS+IN+PARIS,090920071245,2,130,">12:45PM
            </a>
          <sup>2</sup>

        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=2+DAYS+IN+PARIS,090920071500,2,130,">3:00PM
            </a>
          <sup>2</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=2+DAYS+IN+PARIS,090920071715,2,130,">5:15PM
            </a>
          <sup>2</sup>

        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=2+DAYS+IN+PARIS,090920071930,2,130,">7:30PM
            </a>
          <sup>2</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=2+DAYS+IN+PARIS,090920072145,2,130,">9:45PM
            </a>
          <sup>2</sup>

        </span>
        <p></p>
      </dl>
      <dl class="movie-by-day">
        <dt>
          <h5>THE KING OF KONG:</h5>
          <small><span class="length">
          (
    1hr 39mins
    )
   
    <a href="http://www.coolidge.org/node/1034">description</a>

            </span>
          </small>
          <br>
        </dt><span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=THE+KING+OF+KONG,090920071330,1,130,">1:30PM
            </a>
          <sup>1</sup>
        </span>, <span class="time">

          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=THE+KING+OF+KONG,090920071530,1,130,">3:30PM
            </a>
          <sup>1</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=THE+KING+OF+KONG,090920071730,1,130,">5:30PM
            </a>
          <sup>1</sup>
        </span>, <span class="time">

          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=THE+KING+OF+KONG,090920071945,1,130,">7:45PM
            </a>
          <sup>1</sup>
        </span>, <span class="time">
          <a href="https://www.readyticket.net/webticket/webticket2.asp?WCI=BuyTicket&amp;WCE=THE+KING+OF+KONG,090920072200,1,130,">10:00PM
            </a>
          <sup>1</sup>
        </span>

        <p></p>
      </dl>
    </p>
=end