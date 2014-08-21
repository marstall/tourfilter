require 'open4'

#if ENV['RAILS_ENV']=='development'
#  Tidy`.path='/usr/lib/libtidy.dylib'
#else
#  Tidy.path='/usr/lib/libtidy.dylib'
#end

class Match < ActiveRecord::Base
  belongs_to :term
#  belongs_to :page
  has_many   :recommendations, :order=>"id desc"
  has_many   :comments, :order=>"id desc"
  has_many   :user_ticket_offers, :conditions=> "flag_count=0", :order=>'id desc'
  belongs_to :user

  # hack so that match can masquerade as imported_event
  # select l,r,count(*) cnt  from term_edges  where l='destroyer' and network='played_with' group by l,r  order by l,cnt;
  
#  def url
#    if super=~/ticketmaster.com/
#      return "http://ticketsus.at/tourfilter?CTY=37&DURL=#{super}"
#    else
#      return super
#    end
#  end
  
=begin
select terms.*
from terms, matches matches1,matches matches2 
where terms.id=matches2.term_id 
and matches2.page_id=matches1.page_id 
and matches1.date_for_sorting = matches2.date_for_sorting
and matches1.id=165844
and matches2.id<>165844
and matches2.status='notified'
=end  

  def playing_with(num=10)
    return [] if not page_id or page_id==0
    
sql = <<-SQL
    select terms.*
    from terms, matches matches1,matches matches2 
    where terms.id=matches2.term_id 
    and matches2.page_id=matches1.page_id 
    and matches1.date_for_sorting = matches2.date_for_sorting
    and matches1.id=#{id}
    and matches2.id<>#{id}
    and matches2.status='notified'
    group by terms.text
    limit #{num}
    SQL
    terms = Term.find_by_sql(sql)    
    Term.uniques(terms)
  end
  
  def address
    return nil
#    if imported_event and imported_event.venue
#      if venue.address
#        address=venue.address+"<br>"
#      else
#        venue_address=""
#      end
#      if venue.address_2
#        address+=venue.address_2+"<br>"
#      else
##        venue_address=""
#      end
#    else
#      return null
#    end
  end

  def calculated_url
    # if page, return page.url
    # else if place has url, return that.
    # else if venue has url, return that.
    # else return nul
    if page and page.url
      url = page.url 
    elsif page and page.place and page.place.url
      url = page.place.url 
    elsif imported_event and imported_event.venue and imported_event.venue.url
      url =imported_event.venue.url
    end
    url=nil if (url and url.strip.empty?) or url=="/"
    return url
  end
  
  def matches_with_features
    sql=<<-SQL
      select * from matches where feature_id and 
    SQL
  end
  
  def featured
    feature_id||term.feature
  end

  def feature
    if feature_id 
      return Feature.find(feature_id) rescue nil
    else
      return term.feature
    end
  end

  def affiliate_ticket_urls
    tu = ticket_urls(true)
#    puts tu.inspect
    tu
  end

  def stubhub_url
    ticket_urls.each{|ticket_url|
      return ticket_url['url'] if ticket_url['url']=~/stubhub/
    }
    return nil
  end

  def url_ticketmaster_preferred
    tus,low_high=ticket_urls
    tus.each{|ticket_url|
      return ticket_url['url'] if ticket_url['url']=~/ticketmaster/
    }
    return tus.first['url']||"http://www.tourfilter.com"
  end
  
  def has_affiliate_tickets?
    ticket_urls.first.each{|tu|
      return true #if tu['level']=='primary' or tu['level']=='secondary'
    }
    return false
  end

  def ticket_url
    # return the best ticket url. best in order of:
    # 1. VENUE URL
    # 2. PRIMARY TICKETSELLER 
    # 3. SECONDARY TICKETSELLER
    return url if url
    page = self.page
    return page.url(true) if page.url
    imported_events.each{|ie|
        return ie.url if ie.source=='ticketmaster'
        return ie.url if ie.url
      }
  end

  def ticket_urls(imported_only=false)
    begin
      array=Array.new
      hash=Hash.new
      price_low = self.page.price_low rescue nil
      price_high = self.page.price_high rescue nil
      ies = imported_events
      ies.each{|event|
        next if hash[event.url] or hash[event.source]
        next if event.source=='user'
        hash[event.url]=true
        hash[event.source]=true
        array<<{'url'=>event.url,'source'=>event.source,'level'=>event.level,'price_low'=>event.price_low,'price_high'=>event.price_high,
                'num_tickets'=>event.num_tickets}
        price_low=event.price_low if price_low.nil? or event.price_low.to_f<price_low.to_f
        price_high=event.price_high if price_high.nil? or event.price_high.to_f>price_high.to_f
      }
      if self.source and not hash[self.source] and self.source !='user' 
        array<<{'url'=>self.page.url,'source'=>self.source,'level'=>'','price_low'=>self.page.price_low,'price_high'=>self.page.price_high,'num_tickets'=>self.page.num_tickets} 
      else
        array<<{'url'=>self.page.url,'source'=>self.page.domain,'level'=>'','price_low'=>'','price_high'=>'','num_tickets'=>''} 
      end
    rescue
      return [],nil,nil
    end
    return array,price_low,price_high
  end

  def imported_events
    sql = <<-SQL
      select ie.price_low,ie.price_high,ie.* 
      from tourfilter_shared.imported_events ie,matches,imported_events_matches iem
      where iem.imported_event_id=ie.id and iem.match_id=matches.id
        and matches.id=?
      order by price_low
    SQL
    Match.find_by_sql([sql,id])
  end

  def track
    sql = <<-SQL
      select tracks.* from tracks,terms
      where terms.id=?
      and tracks.term_id=terms.id
      limit 1
      SQL
      Track.find_by_sql([sql,term_id]).first rescue nil
  end

  def num_mp3_tracks
    sql = <<-SQL
      select shared_terms.num_mp3_tracks 
      from terms,tourfilter_shared.shared_terms shared_terms,matches
      where matches.term_id=terms.id and terms.text=shared_terms.text
      and matches.id=?
      limit 1
      SQL
      Match.count_by_sql([sql,id])      
  end

  def page=(page)
	self.page_id=page.id
end

  def date_for_sorting_date_only
    # strip out time component
    date_for_sorting.to_date if date_for_sorting
  end

  def imported_event
    if imported_event_id 
      return ImportedEvent.find(imported_event_id)
    else
      return nil
    end
  end
  
  def image
    sql = <<-SQL
      select images.* 
      from images,terms,matches
      where matches.id = ?
      and matches.term_id=terms.id
      and 
      (
        images.term_text=terms.text
        or
        images.term_text=concat("the ",terms.text)
      )
      SQL
    (Image.find_by_sql([sql,self.id])||[]).first
  end
  
  def num_trackers
    term.num_trackers
  end
  
  def term_text
    return nil unless term_id
    return term.text rescue ''
  end

=begin
  def page_no_body
    if @object
      return @object
    end
    if imported_event_id 
      @object=ImportedEvent.find(imported_event_id)
    else
      @object=Page.load_without_body(page_id)
    end
    return @object
  end
=end
  
  def real_page
    if page_id and page_id!=0
      return Page.find(page_id)
    else
      return ImportedEvent.find(imported_event_id)
    end
  end

  def page
    if @object
      return @object
    end
    if imported_event_id 
      @object=ImportedEvent.find(imported_event_id)
    else
      @object=Page.find(page_id)
    end
    return @object
  end

  def self.related_matches(term_text,num=10)
    # algorithm: get list of related terms ... get future matches for each term...
    sql=<<-SQL
      select matches.* from matches,tourfilter_shared.related_terms related_terms,terms
      where related_terms.term_text=?
      and related_terms.related_term_text=terms.text
      and terms.id=matches.term_id
      and matches.source is not null and matches.source<>'user'
      and matches.status='notified' and matches.time_status='future'
      and matches.date_for_sorting>now() 
      group by terms.id
      order by related_terms.count desc 
      limit ?
    SQL
    Match.find_by_sql([sql,term_text,num])
  end

  def self.related_matches_for_user(user,num=10)
    # algorithm: get list of related terms ... get future matches for each term...
    terms=user.terms[0..10].collect{|term|term.text unless term.text=~/'|\\|\/|;|select|delete|update|insert/}.join("','")
    terms="'#{terms}'"
    sql=<<-SQL
      select matches.* from matches,tourfilter_shared.related_terms related_terms,terms
      where related_terms.term_text in (#{terms.gsub('?','')})
      and related_terms.related_term_text=terms.text
      and terms.id=matches.term_id
      and matches.status='notified' and matches.time_status='future'
      and matches.date_for_sorting>now() 
      group by terms.id
      order by related_terms.count desc 
      limit ?
    SQL
    Match.find_by_sql([sql,num])
  end

  def self.featured_matches(term_text,num=5)
    # generate list of popular/related upcoming ticketmaster shows.
    related_matches = Match.related_matches(term_text,num*2) if term_text
    featured_matches=Match.popular_matches(8)
#    featured_matches+=Match.popular_matches(nil,num-4)
    return related_matches,featured_matches
  end

  def self.popular_matches_(num=5)
    sql = <<-SQL
      select external_clicks.term_text,count(*) cnt
      from tourfilter_shared.external_clicks 
      where page_type='band'
      and external_clicks.created_at>adddate(now(), interval -52 hour) 
      group by external_clicks.term_text order by cnt desc limit 50;
    SQL
    matches = Array.new
    external_clicks =ExternalClick.find_by_sql(sql)
    external_clicks.each{|external_click|
      puts external_click.term_text
      sql =  <<-SQL
        select matches.* 
        from matches,terms
        where terms.id=matches.term_id
        and terms.text=?
        and date_for_sorting<adddate(now(),interval 180 DAY) 
        and date_for_sorting>now() 
        and matches.status='notified' 
        and matches.time_status='future'
        and matches.source is not null and matches.source<>'user'
      SQL
      matches+=Match.find_by_sql([sql,external_click.term_text])
      break if matches.size>num
    }
    matches[0..num-1]+Match.popular_matches_(num-4)
  end

=begin
select terms.text,terms.num_trackers
from terms,matches
where terms.id=matches.term_id 
  and date_for_sorting<adddate(now(),interval 180 DAY) 
  and date_for_sorting>now() 
  and matches.status='notified' 
  and matches.time_status='future'
  and matches.source is not null and matches.source<>'user'
group by terms.id order by num_trackers desc 
=end

  def self.popular_matches(match,num=5)
    sql = <<-SQL 
      select matches.*,terms.aggregate_num_trackers
      from terms,matches
      where terms.id=matches.term_id 
        and date_for_sorting<adddate(now(),interval 180 DAY) 
        and date_for_sorting>now() 
        and matches.status='notified' 
        and matches.time_status='future'
        and matches.source is not null and matches.source<>'user'
      group by terms.id order by aggregate_num_trackers desc 
      limit ? 
    SQL
    Match.find_by_sql([sql,num])
  end
#    sql += " and num_trackers>? "

  def comments(num=-1,order_by="id desc")
    sql = " select * from comments where match_id=? "
    sql += " order by #{order_by} "
    sql += " limit ? " if num!=-1
    params=[id]
    params<<num if num!=-1
    Comment.find_by_sql([sql]+params)
  end
  
  def days_away
    return 1000 if not date_for_sorting
    show_time=DateTime.new(date_for_sorting.year,date_for_sorting.month,date_for_sorting.day)
    time_until_show=show_time-DateTime.now
    days_until_show=time_until_show.to_i+1
  end
  
  
  def absolute_date_in_days
    return "" if not date_for_sorting
    event_time=DateTime.new(date_for_sorting.year,date_for_sorting.month,date_for_sorting.day)
    nineteen70 = DateTime.new(1970,1,1)
    time_since_nineteen70=event_time-nineteen70
    days_since_nineteen70 = time_since_nineteen70.to_i
    #ms_since_nineteen70 = days_since_nineteen70 * 24* 60 *60 * 1000
  end
  
  def is_recommended_by_user(user)
    # see if there is a recommendation row with this user_id and this match_id
    sql = "select count(*) from recommendations where user_id=#{user.id}" +
          " and match_id=#{id} "
    Recommendation.count_by_sql(sql)>0
  end

	def page_precis_for_admin(body,query)
	  if body
	    return body.downcase.sub(query.downcase,"<b>"+query+"</b>")
    else
      return ""
    end
  end
  
  def _page_precis_for_admin(body,query,highlight_left="<strong>",highlight_right="</strong>")
    begin
      body.downcase!
      query.downcase!
      query.gsub!(/[,-.:\/()!'";*"]/," ")
      query.strip!
      ind = body.index(" #{query} ")
      return nil if not ind
      precis_start = ind-100
      precis_start=0 if ind<0
      precis =body[precis_start,200]
      precis.gsub! /(\s#{query}\s)/i,"#{highlight_left} #{query} #{highlight_right}" if precis
      return precis
    rescue => e
      return e
    end
  end

  def raw_page_precis_for_admin(body,query,highlight_left="<strong>",highlight_right="</strong>")
    begin
      body.downcase!
      query.downcase!
      query.strip!
      ind = body.index("#{query}")
      return nil if not ind
      precis_start = ind-500
      precis_start=0 if ind<0
      precis =body[precis_start,1000]
#      precis.gsub! ("<","&lt;")
#      precis.gsub! (">","&gt;")
      precis.gsub! /(#{query})/i,"#{highlight_left} #{query} #{highlight_right}" if precis
      ind_gt=precis.index(">")+1
      precis=precis[ind_gt,precis.size-ind_gt]
#      precis = Tidy.open(:show_warnings=>false) do |tidy|
#        tidy.options.show_body_only = true
#        precis = tidy.clean(precis)
#      end
      return precis
    rescue => e
      return e
    end
  end
  
    def medium_time_description
 		if page.place.time_type=="temporary" # festival
 		  return page.place.time_description(use_preposition)
	  end
	  today=false
	  today = true if date_for_sorting<Time.now
	  
    next_week = false
	  next_week = true if date_for_sorting-6.days<Time.now
 		if day
      if today
        return "tonight"
      end
      if SETTINGS['date_type']=='uk'
        if next_week
          s = Date::DAYNAMES[date_for_sorting.wday].downcase
        else
  		 	  s = "#{day} #{Date::MONTHNAMES[month]}".downcase
		 	  end
		 	else
        if next_week
          s = Date::DAYNAMES[date_for_sorting.wday].downcase
        else
  		 	  s = "#{Date::MONTHNAMES[month]} #{day}".downcase
		 	  end
		 	end
		 	return s
	 	end
	 	return ""
  end


  def Match.count_new_future_matches_for_admin
    sql =  " select count(*)"
    sql += " from matches,terms,pages,places "
    sql += " where matches.term_id = terms.id "
    sql += " and pages.id=matches.page_id and places.id=pages.place_id "
    sql += " and matches.status='new' and time_status='future' and (date_for_sorting>now() or date_for_sorting is null)"
    puts sql
    Match.count_by_sql([sql,DateTime.now])
  end

  def Match.new_future_matches_for_admin(num=-1,offset=-1,order_by="places.name asc,terms.text",raw_body=true)
    sql =  " select matches.*, terms.text as match_term_text,pages.url as match_page_url,"
    sql += " places.name as match_page_place_name, substr(pages.body,instr(pages.body,terms.text)-100,200) as match_page_body, "
    #sql += " places.name as match_page_place_name, 'xxx' as match_page_body, "
#    if raw_body 
#      sql += " pages.raw_body as match_page_raw_body," 
#    else
    sql += " '...' as match_page_raw_body,"
#    end
    sql += " terms.source as match_term_source"
    sql += " from matches,terms,pages,places "
    sql += " where matches.term_id = terms.id "
    sql += " and pages.id=matches.page_id and places.id=pages.place_id "
    sql += " and matches.status='new' and time_status='future' and (date_for_sorting>now() or date_for_sorting is null)"
    sql += " order by #{order_by}"
    sql += " limit #{num} " if num!=-1
    sql += " offset #{offset} " if offset!=-1
    puts sql
    Match.find_by_sql([sql,DateTime.now])
  end
  
  def Match.new_future_matches(num=-1,order_by="page_id asc")
    sql = " select matches.* from matches " 
    sql +=" where matches.status='new' and time_status='future' "
    sql +=" order by #{order_by}"
    sql +=" limit #{num}" if num!=-1
    Match.find_by_sql([sql,DateTime.now])
  end

  def Match.recommended_matches_within_n_days_for_user(num,user,order_by="date_for_sorting asc",limit=10000)
    sql =  " select matches.* from recommendees_recommenders,terms,matches,terms_users"
    sql += " where recommendees_recommenders.recommendee_id=? and recommendees_recommenders.recommender_id=terms_users.user_id "
    sql += " and terms_users.term_id=terms.id "
    sql += " and terms.id=matches.term_id "
    sql += " and matches.status='notified' "
    sql += " and matches.day is not null "
    sql += " and matches.time_status='future' "
    sql += " and date_format(date_for_sorting,'%Y/%m/%d')<= "
    sql += "   date_format(adddate(now(),INTERVAL ? DAY),'%Y/%m/%d') "
    sql += " and date_format(date_for_sorting,'%Y/%m/%d')>=date_format(now(),'%Y/%m/%d')"
    sql += " group by terms.id order by #{order_by}"
    sql += " limit ? "
    Match.find_by_sql([sql,user.id,num,limit])
  end
  
  def Match.popular_upcoming_matches_by_source(source,num_days,num)
    source_sql_1=""
    if source=="required"
      source_sql_1="and matches.source is not null"
      source_sql_2="and ie.source is not null"
    elsif source=="any"
    elsif source
      source_sql_1="and matches.source='#{source}'"
      source_sql_2="and ie.source='#{source}'"
    end
    sql = <<-SQL
      (select matches.*,count(*) num_trackers 
      from matches,terms,terms_users 
      where terms.id=terms_users.term_id 
      	and terms_users.term_id=matches.term_id 
      	and date_for_sorting<adddate(now(),interval ? day) 
      	and status='notified' and time_status='future' 
      	and matches.date_for_sorting>now() 
      	#{source_sql_1}
      group by terms_users.term_id)
      union
      (select matches.*,count(*) num_trackers 
      from matches,terms,terms_users,tourfilter_shared.imported_events ie,imported_events_matches iem
      where terms.id=terms_users.term_id 
      	and terms_users.term_id=matches.term_id 
      	and date_for_sorting<adddate(now(),interval ? day) 
      	and matches.status='notified' and time_status='future' 
      	and matches.date_for_sorting>now() 
      	and matches.id=iem.match_id and ie.id=iem.imported_event_id
      	#{source_sql_2}
      group by terms_users.term_id)
      order by num_trackers desc limit ?;
    SQL
    #dedupe
    raw_matches = Match.find_by_sql([sql,num_days,num_days,num])    
    matches_hash=Hash.new
    matches=Array.new
    raw_matches.each{|match|
      matches<<match unless matches_hash[match.term_id]
      matches_hash[match.term_id]=true
    }
    matches
  end
  
  def Match.popular_upcoming_matches(num_days=7,num=10,must_have_source=false)
    sql =  " select matches.*,count(*) num_trackers from terms,matches,places,pages,terms_users "
    sql += " where terms.id=matches.term_id and matches.page_id=pages.id and pages.place_id=places.id and terms.id=terms_users.term_id "
    sql += " and date_for_sorting<adddate(now(),interval #{num_days} DAY) and date_for_sorting>now() and matches.status='notified' and matches.time_status='future' "
    sql += " and matches.source is not null" if must_have_source
    sql += " group by terms.id order by num_trackers desc limit ? "
    Match.find_by_sql([sql,num])
  end
=begin
select matches.*,terms.num_trackers term_num_trackers,terms.text term_text, terms.url term_url 
from matches,terms ,terms_users 
where matches.status='notified' and time_status='future' and matches.term_id=terms.id 
  and date_format(date_for_sorting,'%Y/%m/%d')>= date_format(adddate(now(),INTERVAL 0 DAY),'%Y/%m/%d') 
  and date_format(date_for_sorting,'%Y/%m/%d')< date_format(adddate(now(),INTERVAL 90 DAY),'%Y/%m/%d') 
  and matches.day is not null and matches.term_id=terms_users.term_id and terms_users.user_id=2 
group by matches.id 
order by date_for_sorting asc,page_id 
limit 10000
=end

  def Match.matches_within_n_days_for_user(num,offset,user,order_by="date_for_sorting asc,page_id",limit=10000)
    num=num.to_i
    offset=offset.to_i
    sql =  " select matches.*,terms.aggregate_num_trackers term_num_trackers,terms.text term_text, terms.url term_url from matches,terms"
    sql += " ,terms_users " if user 
    sql += " where matches.status='notified' and time_status='future' "
    sql += " and matches.term_id=terms.id "
    sql += " and date_format(date_for_sorting,'%Y/%m/%d')>= "
    sql += "   date_format(adddate(now(),INTERVAL ? DAY),'%Y/%m/%d') "
    sql += " and date_format(date_for_sorting,'%Y/%m/%d')< "
    sql += "   date_format(adddate(now(),INTERVAL ? DAY),'%Y/%m/%d') "
    sql += " and matches.day is not null "
    sql += " and matches.term_id=terms_users.term_id and terms_users.user_id=#{user.id} " if user
    sql += " group by matches.id "
    sql += " order by #{order_by}"
    sql += " limit ?"
    Match.find_by_sql([sql,offset,num+offset,limit])
  end

  def Match.matches_within_n_days(num=45,order_by="date_for_sorting asc")
    matches_within_n_days_for_user(num,0,nil,order_by)
  end   

  def Match.matches_within_30_days(num=-1,order_by="date_for_sorting asc,pages.id")
    sql = " select matches.* from matches" 
    sql +=" where matches.status='notified' and time_status='future' and "
    sql +=" date_format(date_for_sorting,'%Y/%m/%d')<= "
    sql +="   date_format(adddate(now(),INTERVAL 30 DAY),'%Y/%m/%d') "
    sql +=" and matches.day is not null "
    sql +=" group by matches.term_id "
    sql +=" order by #{order_by}"
    sql +=" limit #{num}" if num!=-1
#    logger.info(sql)
    Match.find_by_sql([sql])
  end         

  def Match.matches_for_today(num=-1,order_by="date_for_sorting asc")
    sql = " select matches.* from matches " 
    sql +=" where matches.status='notified' and time_status='future' "
    sql +=" and date_format(date_for_sorting,'%y/%m/%d')=date_format(?,'%y/%m/%d')"
    sql +=" group by matches.term_id "
    sql +=" order by #{order_by}"
    sql +=" limit #{num}" if num!=-1
    Match.find_by_sql([sql,DateTime.now])
  end         

  def Match.matches_for_today_by_popularity(num=-1)
    sql = " select matches.*,count(*) cnt from matches,terms,terms_users " 
    sql +=" where matches.status='notified' and time_status='future' "
    sql +=" and date_format(date_for_sorting,'%y/%m/%d')=date_format(?,'%y/%m/%d')"
    sql +=" and matches.term_id=terms.id and terms.id=terms_users.term_id "
    sql +=" group by matches.term_id "
    sql +=" order by cnt desc"
    sql +=" limit #{num}" if num!=-1
    Match.find_by_sql([sql,DateTime.now])
  end         

  def Match.count_current()
    sql = " select count(*) from matches" 
    sql +=" where matches.status='notified' and time_status='future' "
    sql +=" and date_for_sorting> ? group by matches.term_id "
    Match.count_by_sql([sql,DateTime.now])
  end         

  #  event.summary=match.match_term_text
  #  event.location=match.match_page_place_name
  #  event.description="#{match.match_page.precis(match.match_term_text,'<<<','>>>')}"
  #  event.url="http://www.tourfilter.com/#{match.match_term_url_text}"

=begin
(
  select matches.*, terms.text as match_term_text,places.name as match_page_place_name,
  from matches,pages,places,terms
  where
  and matches.term_id=terms.id and matches.page_id=pages.id and pages.place_id=places.id
  and matches.status='notified' and time_status='future'
  and date_for_sorting>=now() group by matches.id
)
union
(
  select matches.*,terms.text as match_term_text,venues.name as match_page_place_name,
  from matches,tourfilter_shared.imported_events imported_events,tourfilter_shared.venues venues,terms
  where matches.venue_id=venues.id
  and matches.imported_event_id is not null
  and terms.id=matches.term_id
  and matches.status='notified' and time_status='future'
  and date_for_sorting>now() group by matches.uid limit 10
) limit 10;
=end

  def Match.current_optimized_for_ical(num=-1,order_by="date_for_sorting asc")
    sql = <<-SQL 
      (
        select matches.*, terms.text as match_term_text,places.name as match_page_place_name,
        pages.body as match_page_body from matches,pages,places,terms
        where matches.page_id=pages.id
        and matches.term_id=terms.id and matches.page_id=pages.id and pages.place_id=places.id
        and matches.status='notified' and time_status='future'
        and date_for_sorting> ? group by matches.term_id 
      )
      union
      (
        select matches.*,terms.text as match_term_text,venues.name as match_page_place_name,
        imported_events.body as match_page_body 
        from matches,tourfilter_shared.imported_events imported_events,tourfilter_shared.venues venues,terms
        where matches.venue_id=venues.id
        and matches.imported_event_id=imported_events.id
        and matches.status='notified' and time_status='future' and terms.id=matches.term_id
        and date_for_sorting>? group by matches.uid
      )
    order by #{order_by}
    SQL
    sql += " limit #{num}" if num!=-1
    Match.find_by_sql([sql,DateTime.now,DateTime.now])
  end         

  def Match.current_for_user_optimized_for_ical(user, num=-1,order_by="date_for_sorting asc")
    return if not user or not user.id
    sql =  " select matches.*, terms.text as match_term_text,places.name as match_page_place_name, pages.body as match_page_body "
    sql +=  " from matches,pages,terms_users,terms,places " 
    sql += " where matches.page_id=pages.id "
    sql += " and pages.place_id=places.id and matches.term_id=terms.id "
    sql += " and matches.term_id=terms_users.term_id and terms_users.user_id= ?"
    sql += " and matches.status='notified' and time_status='future' "
    sql += " and date_for_sorting>? group by matches.term_id "
    sql += " order by #{order_by} "
    sql += " limit #{num}" if num!=-1
    Match.find_by_sql([sql,user.id,DateTime.now])
  end         

=begin
def Match.new_future_matches_for_admin(num=-1,order_by="places.name asc,terms.text")
    sql =  " select matches.*, terms.text as match_term_text,pages.url as match_page_url,"
    sql += " places.name as match_page_place_name, pages.body as match_page_body,terms.source as match_term_source"
    sql += " from matches,terms,pages,places "
    sql += " where matches.term_id = terms.id "
    sql += " and pages.id=matches.page_id and places.id=pages.place_id "
    sql += " and matches.status='new' and time_status='future' and (date_for_sorting>now() or date_for_sorting is null)"
    sql += " order by #{order_by}"
    sql += " limit #{num}" if num!=-1
    Match.find_by_sql([sql,DateTime.now])
  end
=end

=begin
select distinct(matches.id),matches.* from matches,tourfilter_shared.features features
 where matches.status='notified' and time_status='future' 
 and date_for_sorting> '2009-12-04 16:19:17' group by matches.feature_id 
 and feature_id=features.id
 order by features.created_at desc
 limit 3
=end

  def entry_url
    "/features/#{self.id}/#{self.term.url_text}/#{self.page.place.url_name}/#{self.date_for_sorting.month}-#{self.date_for_sorting.day}-#{self.date_for_sorting.year}"
  end
=begin
select distinct(matches.id),matches.* from matches,tourfilter_shared.features features,terms
where matches.term_id=terms.id
and terms.text=features.term_text
and matches.status='notified' and time_status='future' 
and date_for_sorting> adddate(now(), interval -1 day)
group by matches.feature_id   
=end

  def Match.recent_with_feature(num=-1,order_by="features.created_at desc")
    #where feature_id=features.id
    sql = <<-SQL
      select distinct(matches.id),matches.* from matches,tourfilter_shared.features features,terms
      where matches.term_id=terms.id
      and terms.text=features.term_text
      and matches.status='notified' 
      group by terms.text
      order by #{order_by}
    SQL
    sql+=" limit #{num}" if num>=0
    Match.find_by_sql([sql,DateTime.now])
  end         

  def Match.current_with_feature(num=-1,order_by="features.created_at desc")
    #where feature_id=features.id
    sql = <<-SQL
      select distinct(matches.id),matches.* from matches,tourfilter_shared.features features,terms
      where matches.term_id=terms.id
      and terms.text=features.term_text
      and matches.status='notified' and time_status='future' 
      and date_for_sorting> adddate(?, interval -1 day)
      group by terms.text
      order by #{order_by}
    SQL
    sql+=" limit #{num}" if num>=0
    Match.find_by_sql([sql,DateTime.now])
  end         

  def Match.current(num=-1,order_by="date_for_sorting asc")
    sql = " select matches.* from matches" 
    sql +=" where matches.status='notified' and time_status='future' "
    sql +=" and date_for_sorting> ? group by matches.term_id "
    sql +=" order by #{order_by}"
    sql +=" limit #{num}" if num!=-1
    Match.find_by_sql([sql,DateTime.now])
  end         

  def Match.current_for_user(user, num=-1,order_by="date_for_sorting asc")
    return if not user or not user.id
    sql = " select matches.* from matches,terms_users,terms" 
    sql +=" where matches.term_id=terms_users.term_id and terms_users.user_id= ?"
    sql +=" and matches.status='notified' and time_status='future' "
    sql +=" and date_for_sorting> ? group by matches.term_id "
    sql +=" order by #{order_by}"
    sql +=" limit #{num}" if num!=-1
    Match.find_by_sql([sql,user.id,DateTime.now])
  end         
  
  
  # this method gets called from both the daemon and the webapp
  # return existing match, or do search and create a 'new' match if one is found
  def Match.search_and_create_matches(term) 
    # are there any matches for this term?
      if term.text.rstrip.empty? or term.text_for_searching.rstrip.empty?
        puts "term.text empty after processing, returning ..."
        return 
      end
      # ok, we need to perform a search for this term
      pages = Page.find_all_matching_term(term) 
      if pages.size>20            
        puts "                    ... more than 20 results found, returning."
        return
      end
      pages.each { |page|
        if not page.place # every page should have a valid place!
          puts "no place found"
          next 
        end
        puts "                     ... found a search hit"
        # presumption here is that if there is any match for this term, mark all the matches as future. In fact, only the most recent should be marked future.
        #Match.update_all("time_status='future',updated_at=#{Time.now}","page_id=#{page.id} and term_id=#{term.id}")

        # in the case of a search hit on a place that already has a recent match for the term, under no circumstances create a new match. we don't want to bug people.
        # however, make the presumption that any matches for this term and place that were future before the daemon ran, will still be future.
        # in other words, if a given band place the same venue every 2 months, all his previous matches will never go away.
        # however we can have a separate thread at the end of the daemon that marks all matches as past that have a calculated_date in the past. [this is old - doesn't work this way anymore]
        match=Match.new
#        begin
          match.page=page
          match.term=term
          match.calculate_date_of_event(false)
          if ((not match.day) and (not term.has_users?)) # don't bother with undated matches that no-one is tracking.
            puts "undated match that no-one is tracking, skipping ...."
            next
          end
          now = DateTime::now
          midnight = DateTime.new(now.year,now.month,now.day,0,0,0)
          if match.day and match.date_for_sorting and match.date_for_sorting< midnight # don't bother if the date is calculable and it's in the past
            puts "match is in the past, skipping ..."
            next
          end
          recent_place_matches = page.place.recent_matches_for(term,match)               # get a list of all recent matches for this place
          if recent_place_matches&&!recent_place_matches.empty?                   # if there are any matches
            recent_place_matches.each { |match|                                   # loop through place.recent_matches
              next if not match
              # when this is run in the webapp, no time_statuses will have a value of 'reevaluating'
              puts "                     ... found a recent match: #{match.id}" 
              # if the status is reevaluating, meaning it was future pre-daemon, mark it future
              # same if it was past before - the shows disappeared, then reappeared on the site
#              puts "match.time_status is #{match.time_status}... "
              if match.time_status=='reevaluating'
                puts "                      ... found match time_status is reevaluating, setting to future"
                match.time_status='future' 
              end
              if match.time_status=='past'     
                puts "                      ... found match time_status is past, setting to future"
                match.time_status='future' 
              end
              match.save                                                          # save
              }
            next                                                                  # don't create a new match
          end
#        rescue => e
#          puts "non fatal error encountered in searching for a match for '#{term.text}' - bad page record?"
#          puts $!
#          puts e.backtrace.join("\n") if e
#            # in case of error, presume the match is still happening.
#          match.time_status='future' if match.time_status=='reevaluating'      # if the status is reevaluating, meaning it was future pre-daemon, mark it future
#          match.save                                                          # save
#          next
#        end
        match.time_status='future'
        match.status="new"
        puts "new match: #{term.text} at #{page.place.name}"
        match.date_block=tidy_block(page.date_block)
        
        match.date_position=page.place.date_type
        match.month_position=page.month_position
        match.save!
 #       match.page= page
#        match.term= term
#        match.calculate_date_of_event(false)
#        match.save
      }
  end
  
  def very_short_time_description
 		if page.place.time_type=="temporary" # festival
 		  return page.place.very_short_time_description
	  end
 		if day
      if SETTINGS['date_type']=='uk'
		 	  return "#{day}/#{month}"
		 	else
		 	  return "#{month}/#{day}"
		 	end
	 	end
 		if month
		 	return Date::MONTHNAMES[month][0..2]
	 	end
	 	return ""
  end

  def short_time_description
 		if page.place.time_type=="temporary" # festival
 		  return page.place.short_time_description
	  end
    time_description(false)
  end

  def time_description(use_preposition=true)
    return "" unless month
 		if page.place.time_type=="temporary" # festival
 		  return page.place.time_description(use_preposition)
	  end
 		if day
 		  preposition="on " if use_preposition
      if SETTINGS['date_type']=='uk'
  		 	return "#{preposition}#{day} #{Date::MONTHNAMES[month]}"
		 	else
  		 	return "#{preposition}#{Date::MONTHNAMES[month]} #{day}"
		 	end
	 	end
 		if month
 		  preposition="in " if use_preposition
		 	return "#{preposition}#{Date::MONTHNAMES[month]}"
	 	end
	 	return ""
  end
  
  # should take today's date and the date of the event and return one of the following
  # tonight
  # tomorrow
  # monday/tuesday/wednesday/thursday/friday/saturday/sunday
  # this week
  # next week
  # this month
  # next month
  # in 2 months
  # in 3 months, etc.
  def when_in_english
    # if the dates are the same, return 'tonight'
    # if date2 is 1 day greater than date1, return 'tomorrow'
    # if day2 is less than 7 days from day1, return monday/tuesday/etc.
    # if week2 is 1 greater than week1, return 'next week'
    # if the months are the same, return 'this month'
    # if month2 is 1 greater than month1, return 'next month'
    # return 'in n months'
    ""
  end
  
  def calculate_date_of_event(do_save=true)
#    begin
#      puts "match.calculate_date_of_event"
      return "day" if day # if either of these are set, no need to re-parse the body.
      return "month" if month
#      puts "here"
#puts page.url(true)      
result,returned_year,returned_month,returned_day = page.calculate_date_of_event(term.text)
      # here we should mark the match with the time and date ...
      puts "calculate_date_of_event returned: #{result}"      
      puts "returned_month: #{returned_month}"	
      puts "returned_year: #{returned_year}"	
      page.log_calculated_date
      self.year= returned_year if returned_year
      self.month= returned_month if returned_month
      self.day= returned_day if returned_day
      puts "page.calculated_month: #{page.calculated_month}"
      	puts "page.calculated_day: #{page.calculated_day}"      
      year_for_sorting = 3000
      month_for_sorting = 12
      day_for_sorting = 28
      year_for_sorting = Integer(self.year) if self.year and Integer(self.year)>2005
      month_for_sorting = Integer(self.month) if self.month and Integer(self.month)>0
      day_for_sorting = Integer(self.day) if self.day and Integer(self.day)>0
      puts "year: #{year_for_sorting}"
      puts "month: #{month_for_sorting}"
      puts "day: #{day_for_sorting}"
      begin
        dt = Date.new(year_for_sorting,month_for_sorting,day_for_sorting)  
      rescue
        # bad date - Feb. 30, etc.
        self.day=nil
        self.month=nil
        puts "BAD DATE!"
        return
      end
      self.date_for_sorting=dt
      self.calculated_date_for_sorting=date_for_sorting
#    rescue => e
#      puts "!!ERROR setting date for match #{id}: #{e}"
#    end
      
    save(self) if do_save
    result
  end
  
  def self.add_leading_zero(s)
    s=s.to_s
    s="0#{s}" if s.size==1
    s
  end
  
  def self.find_dupes_by_term_and_date(term_text,date)
    return nil unless term_text and date
    date=date.to_date
    sql = <<-SQL
      select matches.* from matches,terms
      where matches.term_id=terms.id
      and terms.text="#{term_text.gsub("\"","\\\"")}"
      and left(matches.date_for_sorting,10)='#{date.year}-#{add_leading_zero(date.month)}-#{add_leading_zero(date.day)}'
      and matches.time_status='future'
      and (matches.status='approved' or matches.status='notified')
    SQL
    self.find_by_sql(sql)
  end

  def self.find_dupes_by_term_and_venue_id(term_text,venue_id)
    return nil unless term_text and venue_id
    sql = <<-SQL
      select matches.* from matches,terms,pages,places
      where matches.term_id=terms.id
      and terms.text="#{term_text.gsub("\"","\\\"")}"
      and places.venue_id=#{venue_id}
      and matches.page_id=pages.id and pages.place_id=places.id
      and matches.time_status='future'
      and matches.imported_event_id is null
      and (matches.status='approved' or matches.status='notified')
    SQL
    self.find_by_sql(sql)
  end
  

  def record_edit(user,type,date=nil)
    comment = Comment.new
    comment.user_id=user.id
    comment.match_id=self.id
    text="removed this as inaccurate" if type=="invalidation"
    text="unflagged this - checked and it's accurate" if type=="unflag"
    text="flagged this" if type=="flag"
    text="changed date to #{date.month}/#{date.day}" if type=="new_date"
    comment.text=text
    comment.save
  end

  def Match.tidy_block(s)
     # write s out to a file
     # spawn tidy to process that file, read the output
#      filename = "/tmp/match#{rand(100000)}.tmp"
#      filename2 = "/tmp/tidied#{rand(100000)}.tmp"
      filename = "/tmp/match.tmp"
      filename2 = "/tmp/tidied.tmp"
#      puts "tidying #{s}"
      f = File.new(filename, "w+")
      count = f.write(s)
      f.close
#      puts "wrote #{count}"
#      puts "calling tidy"
      system("tidy --show-body-only true --show-warnings false --quiet true #{filename} >> #{filename2}")
#      puts "tidy called"
      tidied = File.read(filename2)
      File.delete(filename)
      File.delete(filename2)
#      puts "tidied: #{tidied}"
      return tidied
  end

  def ticket_offers
    sql = <<-SQL
      select tio.*,ie.url url,quantity total_quantity
      from tourfilter_shared.ticket_offers tio, tourfilter_shared.imported_events ie,imported_events_matches iem
      where iem.match_id=? and ie.id=iem.imported_event_id and tio.imported_event_id=ie.id
      group by source,section,row,price
      order by price  
    SQL
    Match.find_by_sql([sql,self.id])
  end
  
  def Match.find_by_description_fragment(fragment)
    return nil unless fragment and fragment.strip.size>1
    fragment.strip!
    
    sql = <<-SQL
      select matches.*
       from matches,terms
       where terms.id=matches.term_id
       and matches.status='notified' and matches.time_status='future' and matches.date_for_sorting>now()
       and (terms.text like ?)
       order by date_for_sorting asc
    SQL
    Match.find_by_sql([sql,"#{fragment}%"])
  end
  
  def Match.parse_date_from_description(d)
    r = d.scan(/\(.+?\)/)
    return unless r and r.first
    s = r.first
#    puts "date string: #{s}"
    s = s.chomp(")")[1..s.length-1]
    s = s.split("/")
    puts "s.first: #{s.first}"
    month = s[0].to_i
    day = s[1]
    year = DateTime.now.year.to_i
    this_month = DateTime.now.month.to_i
    year +=1 if this_month>6 and month<6
#    puts "date unparsed: #{year}/#{month}/#{day}"
    return Date.new(year.to_i,month.to_i,day.to_i) 
  end

  def Match.find_by_description(d)
    at_index = d.index("at")
    return nil if not at_index
    term_text = d[0..at_index-1]
#    puts "term_text #{term_text}"
    return if not term_text
    term_text.strip!
    date_index = d.index("(")
    if not date_index
      date_index = d.length 
    else
      date_index-=1 
    end
    place_name = d[at_index+3..date_index]
    return unless place_name
    place_name.strip!
#    puts "place name #{place_name}"
    date = parse_date_from_description(d)
#    puts "date parsed: #{date.to_s}"
    term = Term.find_by_text(term_text)
    return nil if not term
    match = Match.find_by_term_id_and_venue_name_and_date_for_sorting_(term.id,place_name,date)
    return match if match
    return Match.find_by_term_and_place_name_and_date(term,place_name,date)
  end
  
  
  def Match.find_by_term_id_and_venue_name_and_date_for_sorting_(term_id,place_name,date)
    sql = <<-SQL
      select * from matches where
      status='notified'
      and time_status='future'
      and status='notified'
      and left(date_for_sorting,10)=?
      and term_id = ?
      and venue_name = ?
      limit 1
    SQL
    matches = Match.find_by_sql([sql,date,term_id,place_name])
    return matches.first if matches and not matches.empty?
    return nil
  end

  def Match.find_by_term_and_place_name_and_date(term,place_name,date)
    sql = <<-SQL
      select matches.* from matches,pages,places
      where page_id=pages.id
      and place_id=places.id
      and places.name=?
      and term_id=?
      and left(date_for_sorting,10) = ?
    SQL
    places = Match.find_by_sql([sql,place_name,term.id,date])
    return places.first if places and not places.empty?
    return nil
  end

  def dropdown_description
    term_text = (term.nil? ? "?" : term.text)
    s=""
    if imported_event_id
      s = "#{term_text} at #{self.venue_name}"
    else
      s = "#{term_text} at #{self.page.place.name}"
    end
    s= "#{s} (#{very_short_time_description})" if self.day
    s.downcase
  end

end


