require "../app/models/acts_as_indexable.rb" if $mode=="import_daemon"

class ImportedEvent < ActiveRecord::Base
#   validates_format_of :body,
#                       :with => /[^<>]/,
#                       :message => " can't contain HTML"
   
   
   @cnn='unshared'
   unless $mode=="import_daemon"
     require "../config/environment.rb" if $mode=="daemon"
     establish_connection "shared_#{ENV['RAILS_ENV']}" 
     @cnn='shared'
   end
   
  include ActsAsIndexable

  belongs_to :venue
  belongs_to :user
  
  has_many :images,:dependent=>:destroy
  
  has_many :ticket_offers
  
  attr_accessor :post_as

  has_many :taggings,:dependent=>:destroy
  has_many :tags, :as=>:hashtags, :through=>:taggings
  
  
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
    ArtistTerm.find_all_by_imported_event_id(id)
  end

  def user_status
    
  end

  
  def formatted_body(metro_code,highlight=nil)
    max_url_length = 40
    replace_hash = {
      'hashtag'=>/\#[^\s]+/,
      'url'=>/http\:\/\/[^\s]+/,
      'large_url'=>/http\:\/\/[^\s<]{#{max_url_length},}/
      }
    desc = "#{body}"
    desc.gsub!(replace_hash['hashtag'],'<span class=\'hashtag\'><a href=\'/'+metro_code+'/flyers/\0\'>\0</a></span>')
    desc.gsub!("/#","/")
#    desc.gsub!(replace_hash['url'],'<span class=\'flyer_url\'><a href=\'\0\'>\0</a></span>')
    # now truncate urls ...
    desc2 = ""+desc
    desc.scan(replace_hash['url']) {|m|
      anchor_text= m.size<=max_url_length ? m : m[0..max_url_length-3]+"..."
      desc2.gsub!(m,"<span class='flyer_url'><a href='#{m}'>#{anchor_text}</a></span>")
      }
    desc2.gsub!(/#{highlight}/i,"<span class='search_highlight'>#{highlight}</span>") if highlight
    return desc2
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

  def very_short_time_description
    if SETTINGS['date_type']=='uk'
	 	  return "#{date.day}/#{date.month}"
	 	else
	 	  return "#{date.month}/#{date.day}"
	 	end
  end
  
  def oneup_url(metro_code)
    "/#{metro_code}/flyer/#{id}"
  end

  def short_time_description
    s=""
    if SETTINGS['date_type']=='uk'
	 	  s = "#{date.day} #{Date::MONTHNAMES[date.month]}"
	 	  s+="-#{end_date.day}" if multiple_days && end_date && end_date>date
	 	else
	 	  s= "#{Date::MONTHNAMES[date.month]} #{date.day}"
	 	  s+="-#{end_date.day}" if multiple_days && end_date && end_date>date
	 	end
	 	return s
  end
  
#  def address
#    venue.address
#  end
  
  def address=(address)
    return unless venue
    venue.address=address
    venue.save
  end
  
  def process_image
    image||=Image.new
    image.imported_event_id=self.id
    if image.url!=image_url
      puts " downloading and processing image url #{image_url}"
      image.url = image_url
      image.problem='no'
      return image.process
#      self.save
    end
  end
  
  def image
    if images and images.size>0
      return images[0]
    else
      return nil
    end
  end
  
#  def image_url
#    if images and images.size>0
#      return images[0].large_url
#    else
#      return super.image_url
#    end
#  end
  
  def ImportedEvent.popular_flyers(params={},options={})
    return []
  end
  
  def ImportedEvent.all_flyers(params={},options={})
     if params[:order]=='popularity'
       return popular_flyers(params,option)
     end
     options||={}
     tags=params[:tags]
     query=params[:query]
     user_id=params[:user_id]
     user = params[:user]
     puts "!!! possible sql injection" and return nil if tags!=/^[a-z]$/ #sql injection
     metro_code=params[:metro_code]
     order=params[:order]||'imported_events.created_at desc'
     num=params[:num]||50
     start=params[:start]||0

     select_sql = "select imported_events.* from imported_events"
     order_sql= params[:order] || 'imported_events.created_at desc'
     group_by_sql = "group by imported_events.id"

     if tags
       if Tag.is_supertag(tags)
         tags_sql = " and category=?"
       else
        select_sql +=",taggings,tags"
        tags_sql = "and taggings.imported_event_id=imported_events.id and taggings.tag_id=tags.id and tags.text=?"
       end
     else
       tags_sql = ""
     end
     query_sql =""
     if query
       query
       query_sql = " and (body like ? or username=? or category=?)"
     end


     if user_id
       order= 'ieu.created_at desc'
       select_sql+=",imported_events_users ieu"
       user_id_sql = " and ieu.imported_event_id=imported_events.id and ieu.user_id=#{user_id} and ieu.deleted_flag=false "
     end
     metro_sql = metro_code ? " and imported_events.metro_code='#{metro_code}' " : ""
     recommenders_sql = ""
     if options[:show_recommenders]
       if user and user.recommenders.size>0
         order_sql= 'ieu.created_at desc'         
         select_sql+=",imported_events_users ieu"
         ids  = user.recommenders.collect{|u|u.id}.join(",")
         recommenders_sql = " and ieu.imported_event_id=imported_events.id and ieu.user_id in (#{ids}) and ieu.deleted_flag=false "
         group_by_sql = " group by imported_event_id,user_id "
       else
         return []
       end
     end

     if options[:show_flagged]=="flagged_only"
       flagged_sql = " and flagged is not null"
     else
       flagged_sql = " and flagged is null"
     end
     sql = <<-SQL
        #{select_sql}
        where source='user'
        and image_url is not null
        #{metro_sql}
        #{flagged_sql}
        #{tags_sql}
        #{query_sql}
        #{user_id_sql}
        #{recommenders_sql}
        #{group_by_sql}
        order by #{order_sql}
        limit ?
        offset ?
      SQL
      args=[sql]
      args<<tags if tags
      if query
        args<<"%#{query}%" 
        args<<query
        args<<query.sub("#","")
      end
      args<<num.to_i
      args<<start.to_i
      puts sql
      ImportedEvent.find_by_sql(args)
    end

  def get_url
    if url 
      return url 
    else
      return "url"
    end
  end
  
  def has_text?
    return true if body and body.strip.size>0
    return true if venue_name and venue_name.strip.size>0
  end
  
  def is_owner(user,metro_code)
    return false if ((not user) or (not metro_code))
    (user.id==user_id) and (user_metro==metro_code)
  end
  
  def do_hashtag_process
    tags = []
    body.scan(/\#[^ ]+/).each{|_tag|
      tag = Tag.find_or_create(_tag)
      tags<<tag
      tagging = Tagging.new
      tagging.imported_event_id=id
      tagging.tag_id=tag.id
      tagging.save
    }  if body
    return tags
  end

  def do_term_search_process
    shared_terms = SharedTerm.find_terms_in(self)
    i=0
    shared_terms.each{|shared_term|
      i+=1
      text = shared_term.text
      puts "evaluating shared_term #{text} to add ..."
      at = ArtistTerm.find_by_artist_name_and_term_text_and_status(text,body,'invalid')
      if at
        puts "found invalid at like this (#{at.id}:#{at.status})"
        next
      end
      status='term_found'
      save
      artist_term = ArtistTerm.new
      artist_term.imported_event_id=id
      artist_term.artist_name=body
      artist_term.term_text=text
      artist_term.status='new'
      pref="   "
      begin
        artist_term.calculate_match_probability
        artist_term.save 
        pref="+++"
      rescue => e
        puts e
      end
      puts "#{pref} [#{text}]\t\t#{body} (#{i} of #{shared_terms.size})"
    }
    
  end
  
  def find_duplicate

  end

end
