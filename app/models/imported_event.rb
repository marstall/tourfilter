require "../app/models/acts_as_indexable.rb" if $mode=="import_daemon"

class ImportedEvent < ActiveRecord::Base
   @cnn='unshared'
   unless $mode=="import_daemon"
     require "../config/environment.rb" if $mode=="daemon"
     establish_connection "shared_#{ENV['RAILS_ENV']}" 
     @cnn='shared'
   end
   
  include ActsAsIndexable

  belongs_to :venue
  belongs_to :user
  
  has_many :ticket_offers
  
  def valid_terms
    sql = <<-SQL
      select * from artist_terms where status='valid' and imported_event_id=?
    SQL
    ArtistTerm.find_by_sql([sql,id])
  end

  def likely_terms
    sql = <<-SQL
      select * from artist_terms where match_probability='likely' and imported_event_id=?
    SQL
    ArtistTerm.find_by_sql([sql,id])
  end

  def artist_terms
    sql = <<-SQL
      select * from artist_terms where artist_name
    SQL
  end

  def user_status
    
  end

  def find_dupe
    ImportedEvent.find_by_term_and_date(body,date)
  end

  def self.find_future_valid_by_metro_code(source=nil,metro_code=nil)
    sql = <<-SQL
      select imported_events.* from imported_events,tourfilter_#{metro_code}.imported_events_matches iem
      where date>now()
      and iem.imported_event_id=imported_events.id
      and imported_events.status='made_match' 
      #{source ? " and source='#{source}' " : ""}
      group by imported_events.id 
      order by source, venue_name
    SQL
    self.find_by_sql(sql)
  end
  
  def self.find_future_valid(source=nil,metro_code=nil)
    return find_future_valid_by_metro_code(source,metro_code) if metro_code
    sql = <<-SQL
      select imported_events.* from imported_events
      where date>now()
      and imported_events.status='made_match' 
      #{source ? " and source='#{source}' " : ""}
      order by source, venue_name
    SQL
    self.find_by_sql(sql)
  end
  
=begin
select imported_events.* from imported_events,venues,metros_venues mv
where date>now()
and imported_events.venue_id=venues.id
and mv.metro_code='boston'
and mv.venue_id=venues.id
and match body against ('-parking -vip' in boolean mode)
and imported_events.source='ticketmaster'
=end

  def self.find_all_future(metro_code)
    sql = <<-SQL
      select imported_events.* from imported_events,venues,metros_venues mv
      where date>now()
      and imported_events.venue_id=venues.id
      and mv.metro_code=?
      and mv.venue_id=venues.id
      and imported_events.source='ticketmaster'
    SQL
    imported_events = self.find_by_sql([sql,metro_code])
    ret = Array.new
    imported_events.each{|ie|
      ret<<ie if ie.body !~ /parking|vip/i
    }
    return ret
  end
    

  def self.find_by_term_and_date(term_text,date)
    sql = <<-SQL
      select ie.* 
      from artist_terms at,imported_events ie
      where at.status='valid'
      and at.artist_name=ie.body
      and (ie.status='made_match' or ie.status='processed_unknown_disposition')
      and at.term_text=?
      and ie.date=?
      group by ie.source
      order by level
    SQL
    ImportedEvent.find_by_sql([sql,term_text,date])
  end
#      and left(ie.date,10)=left(?,10)

  def place
#    puts "imported_event.place has self.connection.current_database: #{self.connection.current_database}"
#    puts "imported_event.place has self.connection.execute('select database()'): #{self.connection.execute('select database()').fetch_row.first}"
    place = PlaceStub.new
    if venue_id
      place.name= venue.name
      place.url= venue.affiliate_url_1
    end
    place
  end

  
  def precis(foo=nil,boo=nil,moo=nil)
    body
  end
  
  def domain
    begin
      url =url(true)
      uri = URI.parse(url)
      domain = uri.host.sub("www.","")
      domain = domain[0..32]
      domain
    rescue
      return "website"
    end
  end
  
  
  def url(real=false)
    if not real
      if super=~/ticketmaster.com/
        return "http://ticketsus.at/tourfilter?CTY=37&DURL=#{super}"
      elsif super
        return super
      else
        return venue.affiliate_url_1
      end
    else
      return super
    end
  end
  
    
  def delete_tickets
    TicketOffer.delete_all("imported_event_id=#{id}")
  end

  def find_and_save_ticket_offers(total,fast_forward=false)
    # load up the right parser for this source
    # ask it to fetch and parse the url and return an array of ticket_offers
    # save each one
    delete_tickets
    parser = Object.const_get("#{source.capitalize}Parser").new
    ticket_offers = parser.extract_ticket_offers(url(true),fast_forward)
    self.num_tickets=0
    self.price_low=nil
    self.price_high=nil
    ticket_offers.each{|to|
      if to.is_a? TicketOffer
#        puts "it's a TicketOffer"
        to.imported_event_id=id
        self.num_tickets+=to.quantity if to.quantity
        self.price_low=to.price if self.price_low.nil? or self.price_low>to.price
        self.price_high=to.price if self.price_high.nil? or self.price_high<to.price
        to.source=source
        to.save
      else
#        puts "it's a num/string"
        to=to.to_i
        self.price_low=to if self.price_low.nil? or self.price_low>to
        self.price_high=to if self.price_high.nil? or self.price_high<to
        num_tickets=nil
      end
    } if ticket_offers
    texts = valid_terms.collect{|term| term.term_text }
    valid_terms_string = texts.first #join(',')
    @@i||=0
    puts "[#{@@i+=1}/#{total}] #{self.id} #{body[0..20]} [#{valid_terms_string}] #{self.num_tickets==0 ? 'tickets': self.num_tickets} @ $#{self.price_low}-$#{self.price_high}"
    save
  end

end
