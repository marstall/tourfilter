#require "net/http"
#require 'open-uri'
require 'digest/md5'
require 'hpricot'

include UrlFetcher

class Place < ActiveRecord::Base
  belongs_to :metro
  has_many :pages
#  has_many :future_pages, # pages with status of 'future'
#           :class_name => "Page",
#           :conditions => "pages.status='future'"
  has_many :recent_matches, # matches less then one month old
           :class_name => "Match",
           :conditions => ["matches.created_at > ?", 2.months.ago]

  has_many :place_images_with_term_text,
           :class_name => "PlaceImage",
           :conditions => ["term_text is not null"]
  
   def current_with_feature(num=-1,order_by="features.created_at desc")
     #where feature_id=features.id
     sql = <<-SQL
       select distinct(matches.id),matches.* from matches,tourfilter_shared.features features,terms,pages
       where matches.term_id=terms.id
       and matches.page_id = pages.id
       and pages.place_id=?
       and terms.text=features.term_text
       and matches.status='notified' and time_status='future' 
       and date_for_sorting> adddate(?, interval -1 day)
       group by terms.text
       order by #{order_by}
     SQL
     sql+=" limit #{num}" if num>=0
     Match.find_by_sql([sql,id,DateTime.now])
   end         

  def future_pages
    if id
      Page.find_by_sql("select * from pages where place_id=#{self.id} and pages.status='future'")
    elsif venue_id
      return nil
    else
      return nil
    end
  end
    
  def self.logit(s)
    puts s
  end
  
  def short_name
    sn=name.gsub("middle","").strip
    return "#{sn}_"
    words = sn.scan(/[\w']+/)
    if words and words.length>2
      return words[0]+" "+words[1]+"--"
    else
      return "#{sn}-"
    end
  end

  def logit(s)
    logger.info s
    puts s
  end

  def venue
    return nil unless venue_id
    Venue.find(venue_id)
  end

  

  def url_name
    URI::encode(name).gsub("'","%27")
  end

  def make_month_map
    @month_map=Hash.new
    @month_map["january"]=1
    @month_map["february"]=2
    @month_map["march"]=3
    @month_map["april"]=4
    @month_map["may"]=5
    @month_map["june"]=6
    @month_map["july"]=7
    @month_map["august"]=8
    @month_map["september"]=9
    @month_map["october"]=10
    @month_map["november"]=11
    @month_map["december"]=12
    @month_map["jan"]=1
    @month_map["feb"]=2
    @month_map["mar"]=3
    @month_map["apr"]=4
    @month_map["may"]=5
    @month_map["jun"]=6
    @month_map["jul"]=7
    @month_map["aug"]=8
    @month_map["sep"]=9
    @month_map["sept"]=9
    @month_map["oct"]=10
    @month_map["nov"]=11
    @month_map["dec"]=12
    @month_map
  end

  # go through each page, find <img, find band names near image, store in the database
  def calculate_term_offsets(page)
    term_offsets=Hash.new
    page.future_matches.each{|match|
      index = page.raw_body.index(match.term.text)
      term_offsets[index]=match.term.text if index 
    }
    term_offsets
  end

  def all_terms
    @all_terms||@all_terms = Term.find_by_sql("select terms.* from terms,matches,pages where page_id=pages.id and pages.place_id=#{id} and matches.term_id=terms.id and matches.status='notified'")
  end


  def calculate_term_offsets_(page)
    term_offsets=Hash.new
    all_terms.each{|term|
      index = page.raw_body.index(term.text)
      term_offsets[index]=term.text if index
    }
    term_offsets
  end

  def find_term_in_url(url)
    puts url
    matches=Array.new
    url_blocks = url.scan(/[^\/]+/)
    filename=url_blocks.last
    return nil if filename.scan(/\d/).size > 5 # no bandname should have so many numbers in it
    filename.gsub!(/(jpg|jpeg)/,"")
    filename = filename.gsub(/[-_&]|\s/,"").downcase
    all_terms.each{|term|
      term_text = term.text.gsub(/[-_&]|\s/,"").downcase
      next if term_text.size<=3
#      next if term_text !~ /lonely/
#      puts "filenam: #{filename}"
#      puts "term_text: #{term_text}"
#      puts "index: #{filename.index(term_text)}"
      ind = filename.index(term_text)
      if ind
        matches<<term.text 
#        puts "match: #{term.text}"
      end
    }
    return nil if matches.empty?
    matches.sort{|a,b|b.size<=>a.size}
    puts "#{matches.first}"
    matches.first
  end

  def calculate_term_text(page,raw_url,term_offsets)
    term_text = find_term_in_url(raw_url)
    return term_text if term_text
    diffs = Hash.new
    url_offset = page.raw_body.index(raw_url)
    return unless url_offset
    term_offsets.each_key{|term_offset|
      diff = (term_offset-url_offset).abs
      diffs[diff]=term_offsets[term_offset]
    }
    return nil if diffs.empty?
    closest = diffs.sort.first
    if closest[0]<100
      ret = "#{closest[1]}" 
      puts ret
      ret
    else
      return nil
    end
  end

  @@terms=nil

  def process_urls
    # create a hash of all terms.
    if not @@terms
      @@terms=Hash.new 
      Term.find(:all).each{|term|
        @@terms[term.text.downcase]=term.id
      }
    end
    terms=@@terms
    # loop through all <a> ` in the raw_body
    pages.each{|page|
      next unless page.raw_body
      puts page.url(true)
      begin
        doc = Hpricot(page.raw_body[0..65000])
        (doc/"a").each{|a|
          name =a.inner_html
          next unless name
          name =name.gsub(/<([^>]+)>/,"").downcase
          next unless name and not name.strip.empty?
          if @@terms[name]
            url = a.attributes['href']
            next if url =~/ticketmaster/
            next unless url and not url.strip.empty? and url =~/^http/
            puts "#{name}:#{url}"
            term_url=TermUrl.new
            term_url.term_id=@@terms[name]
            term_url.term_text=name
            term_url.url=url
            term_url.source_page_id = page.id
            begin
              term_url.save
            rescue
            end
            term = Term.find(@@terms[name])
            if term.url!=url
              term.url = url  # whomp over existing one with this one
              term.save
            end
          end
      }
      rescue Hpricot::ParseError
        puts "Hpricot error! Skipping."
      end
    }
  end

  def process_images
    self.num_images=0
    future_pages.each{|page|
      next unless page.raw_body 
      if page.url(true)=~/\$\{/
        puts "template url, skipping"
        next
      end
      term_offsets = calculate_term_offsets(page)
      puts "... #{page.url(true)} (#{page.raw_body.size} bytes)"
      uri = URI::parse(page.url(true))
      begin
        doc = Hpricot(page.raw_body[0..65000])
  #      puts doc.inspect
        (doc/"img").each{|img|
          url = raw_url =  img.attributes['src']
          next unless url=~/(jpeg|jpg)$/
  #        puts
  #        puts url
          width = img.attributes['width']
          height = img.attributes['height']
          title = img.attributes['title']||img.attributes['alt']
          unless url=~/^http/
            url_base = "http://#{uri.host}"  # starts with a slash, so just add to the host with no slash
            if url !~ /^\//
              # no leading slash, meaning the path is relative to the page's immediate directory - the base is the full url up to the final slash
              url_base+="/"
              blocks = uri.path.scan(/[^\/]+/)
              blocks[0..blocks.size-2].each{|block|
                url_base="#{url_base}#{block}/"
                } if blocks.size>1
            end
            url="#{url_base}#{url}"
          end
          term_text = calculate_term_text(page,raw_url,term_offsets) # find closest term
          begin
            #puts url
            place_image = PlaceImage.new
            place_image.url = url
            place_image.width = width
            place_image.height = height
            place_image.alt_text = title
            place_image.place_id = id
            place_image.page_id = page.id
            place_image.term_text=term_text
            place_image.save
            self.num_images+=1
  #          puts self.num_images
          rescue
          end
          self.just_save # to save the updated num_images
        }
      rescue Hpricot::ParseError
        puts "Hpricot error! Skipping."
      end
    }
  end

  # what is a date?
  # either:
  # (
  # a full month name or an abbrieviated month name
  # followed by one or more spaces
  # followed by a number between 1 and 31, with optional leading zero, followed by a space, comma or dash
  # )
  # or
  # (
  # a number between 1 and 12, with optional leading zero
  # followed by a forward slash
  # followed by a number between 1 and 31, with option leading zero, followed by a non-digit character
  # )
  #  
  # also, > followed by a number followed by < is probably a day-of-month, if the month is set.
  #
  # if we look in the block previous to the match (say 50 characters) and find the latest instance
  # of a date, then that's the date. But we must look in the raw body.
  # 
  def calculate_regexps
    make_month_map
    month_name_expression = "Jan(?:uary)?|Feb(?:ruary)?|Mar(?:ch)?|Apr(?:il)?|May|Jun(?:e)?|Jul(?:y)?|Aug(?:ust)?|Sept?(?:ember)?|Oct(?:ober)?|Nov(?:ember)?|Dec(?:ember)?"
    # day_expression: any 2 digits not followed by a digit - this avoids 4-digit years being interpreted as days - but not 0 or 00
    day_expression = "(?:(?:[123][0-9])|(?:[0][1-9])|(?:[1-9]))(?![0-9])" 
    month_number_expression = "[01]?[0-9]"

    # get the header chunk
    # if the month is known from the templating, try just looking for the day by itself
#    logit "date:block\n:#{date_block}"
    logit "SETTINGS['date_type'],#{SETTINGS['date_type']}"
    if SETTINGS['date_type']=='uk'
      day_match_position=0
      month_match_position=1
      month_name_regexp="(#{day_expression})(?:st|nd|rd|th)?(?:\<br\>)?\s(#{month_name_expression})\.?"
      month_number_regexp="(#{day_expression})\/(#{month_number_expression})" # for example, "4/29" or "03/01"
    else
      month_name_regexp="(#{month_name_expression})\.?\s(#{day_expression})"
      month_number_regexp="(#{month_number_expression})\/(#{day_expression})" # for example, "4/29" or "03/01"
      month_match_position=0
      day_match_position=1
    end
    regexps=[month_name_regexp,month_number_regexp] # add any standard expressions to this array
#    regexps=[month_number_regexp] # add any standard expressions to this array
    # see if a custom date regexp has been specified
    # if so, sub out variables and use it.
    if date_regexp and not date_regexp.chomp.empty?
      logit "custom regexp found."
      regexp=date_regexp
      day_index = regexp.index("{day")
      month_index = regexp.index("{month")
      if day_index and month_index and day_index<month_index 
        day_match_position=0
        month_match_position=1
      else
        day_match_position=1
        month_match_position=0
      end
      regexp=regexp.gsub(/\{month_name\}/,"(#{month_name_expression})")
      regexp.gsub!(/\{month_number\}/,"(#{month_number_expression})")
      regexp.gsub!(/\{day\}/,"(#{day_expression})")
      regexps=[regexp] # custom regexp replaces the standard regexps
    end
    best_match_index=0
    best_match=nil
    all_regexps=""
    # here we must concatenate all the regexps into one to search the entire date block
    # for instances of any date formats.
    regexps.each_with_index{|regexp,i|
#      logit "component regexp: #{regexp}"
      all_regexps += "|" if i!=0
      all_regexps += "(?:#{regexp})"
    }
    logit "                    all_regexps: #{all_regexps}"
  {:all_regexps=>all_regexps,:month_match_position=>month_match_position,:day_match_position=>day_match_position}
  end


  def create_temp_page(page,year,month,day)
    return if page.nil?
    zero_plus_month=""
    zero_plus_month="0" if month<10
    zero_plus_month+=String(month)
    if day
      zero_plus_day=""
      zero_plus_day="0" if day<10
      zero_plus_day+=String(day)
    end
    new_url = page.url(true).gsub(/\$\{0m\}/,zero_plus_month)
    new_url = new_url.gsub(/\$\{0d\}/,zero_plus_day) if zero_plus_day
    new_url = new_url.gsub(/\$\{m\}/,String(month))
    new_url = new_url.gsub(/\$\{m-1\}/,String(month-1))
    new_url = new_url.gsub(/\$\{m+1\}/,String(month+1))
    new_url = new_url.gsub(/\$\{Mon\}/,Date::MONTHNAMES[month][0..2])
    new_url = new_url.gsub(/\$\{mon\}/,Date::MONTHNAMES[month][0..2].downcase)
    new_url = new_url.gsub(/\$\{Mont\}/,Date::MONTHNAMES[month][0..3])
    new_url = new_url.gsub(/\$\{mont\}/,Date::MONTHNAMES[month][0..3].downcase)
    new_url = new_url.gsub(/\$\{Month\}/,Date::MONTHNAMES[month])
    new_url = new_url.gsub(/\$\{month\}/,Date::MONTHNAMES[month].downcase)
    new_url = new_url.gsub(/\$\{yyyy\}/,String(year))
    new_url = new_url.gsub(/\$\{yy\}/,String(year)[2..3])
    new_url = new_url.gsub(/\$\{d\}/,String(day)) if day
    puts "evaluating template-derived url: #{new_url}"

  begin
    # if this url already exists, don't create a new page record with a dupe - 
    # but do mark the existing record as still in the future!    
    page2 = Page.find_by_url(new_url)
    page2.status='future'
    page2.year=year
    page2.month=month
    page2.day=day
    puts "                      ... found existing url, marking as future"
    page2.save
    return   
  rescue
    # couldn't find this url, so create a new page record for it.
    puts "                      ... creating new url, marking as future"
    new_page = Page.new
    new_page.flags="template-based"
    new_page.status='future'
    new_page.place=page.place
    new_page.url=new_url
    new_page.meth=page.meth
    new_page.year=year
    new_page.month=month
    new_page.day=day
    new_page.save
    end
  end
  
  def generate_urls
    #pages = Page.find(:all, :conditions => [ "url regexp '\{'"])

    #cycle through each future page, and create rows going out 3 months, or update existing rows as "future"
    future_pages.each {|page|
      next if not page.url =~ /\{/
      puts "expanding template url: #{page.url}"
      url = page.url
      # does this have a month variable?
      has_day=false
      has_month=false
      has_year=false

      has_day=true if url =~ /\$\{0?d+\}/ 
      has_month=true if url =~ /\$\{0?m+(?:\-1)?\}|\$\{mont?h?\}/i
      has_year=true if url =~ /\$\{y+\}/ 

      now = DateTime.now
      if has_day&&has_month&&has_year # day included ...
         puts "day-month-and-year url: #{page.url}"
         0.upto(60) do  |i| # go out 60 days
           date=now+i # add i days to now
           create_temp_page(page,date.year,date.month,date.day)
         end
       end
      if has_month&&has_year&&!has_day # the most common case
        puts "month-and-year url: #{page.url}"
        0.upto(2) do  |i|
          date=now>>i # add i months to now
          create_temp_page(page,date.year,date.month,nil)
        end
      end
    }    
  end

  def calculated_url
    if url and not url.strip.empty?
      return url 
    elsif future_pages and future_pages.first
      return future_pages.first.url     
    else
      return nil
    end
  end

=begin
  def fetch_url(url_text)
    begin
      user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      obj = open(url_text, "User-Agent" => user_agent)
      obj.read
    rescue Exception
      agent.set_proxy("psychoastronomy.org",51234)
      
      puts "error fetching url: #{$!}"
      puts "continuing ... "
    end
  end
=end
  
  def remove_meta_tag(body)
    return if not body
    body.gsub(/<meta([^>]+)>/," ") # get rid of meta tag
  end

  def remove_comments(body)
    return if not body
    body.gsub(/<\!\-\-.+?\-\->/,"") # get rid of comments
  end

  def fetch_urls
    #load all future-urls from the page table
#    pages = Page.find(:all, :conditions => [ "status='future'"])
    puts "entering fetch_urls ..." 
    error=nil
    # crawl the value of all urls and puts them into the body column of the page table
    future_pages.each { |page| 
      if page.url(true).empty?
        puts "empty url, skipping"
        next
      end
      if page.url(true)=~/\$\{/
        puts "template url, skipping"
        next
      end
      begin
        puts "crawling "+page.url(true)+"..."
        body = fetch_url(page.url(true)) 
      rescue
        error="" if not error
        error+="Error fetching #{page.url(true)}: #{$!}<br>"
        puts "error crawling #{page.url(true)}: #{$!}!"
        page.num_consecutive_errors||=0
        page.num_consecutive_errors+=1;
        page.save
        next
      end
      if body.nil?||body.strip.empty? 
        puts "empty body"
        page.num_consecutive_errors||=0
        page.num_consecutive_errors+=1;
        page.save
        next
      end
      puts "body is #{body.size} characters long" if !body.nil?
      body = body.gsub(/\s+/," ") # collapse all consecutive whitespace into a single space
      body = page.remove_accents(body)
      body = remove_meta_tag(body)
      body = remove_comments(body)
      page.raw_body=body||""
      raw_body_md5= Digest::MD5.hexdigest(page.raw_body||"")
      body = body.gsub(/<([^>]+)>/," ") # get rid of all html
      body = body.gsub(/&nbsp;/," ") # replace &nbsp; with space
      body = body.gsub(/&amp;/,"&") # replace &amp; with &
      body = body.gsub(/&quot;/,"\"") # replace &quot; with &
      body = body.gsub(/&lt;/,"<") # replace &lt; with <
      body = body.gsub(/&gt;/,"<") # replace &gt; with >
      body = body.gsub(/[\r\n\-\,\.\:\/\(\)\!\'\"\;\*\&\"]/," ") # replace punctuation with space
      page.body = body
      page.num_consecutive_errors=0
      # see if the page has changed since the last time. if so, update the md5 and mark it as changed now.
      if (page.raw_body_md5==nil or (raw_body_md5!=page.raw_body_md5))
        page.raw_body_md5=raw_body_md5
        page.last_changed_at=DateTime.now
      end
      #page.sanitize_body
      page.save
    } if !pages.nil?  
    error
  end

  def url_name
    t = name.downcase # make it all lowercase
    t = t.gsub(/\s/,"_") #substitute underscores for spaces
  end

  def pages_as_text
    return @pages_as_text if @pages_as_text
    s="";
    future_pages.each{ |p| 
      s+="#{p.id} "
      s+="#{p.url(true).strip}" 
      s+=" #{p.meth}" if p.meth=~/POST|MANUAL/
      s+="\n"
      } if future_pages
    s.strip
  end

  def self.find_by_name(n)
    place = super(n)
    if not place
      places = Place.find_by_sql(["select places.* from places,tourfilter_shared.venues venues where venue_id=venues.id and venues.name=?",n])
      place=places.first if places
    end
    return place
  end

  def self.find_in_metro_like_name(metro_code,n)
    sql=<<-SQL
      (select places.name name,metros.name city,state from places,metros where metro_id=metros.id and places.name like ?) 
        union
      (select venues.name name,city,state 
        from tourfilter_shared.venues venues,tourfilter_shared.metros_venues mv
        where mv.venue_id=venues.id
        and mv.metro_code=?
        and venues.name like ?)
      limit 10
    SQL
    Place.find_by_sql([sql,"%#{n}%",metro_code,"%#{n}%"])
  end

  def self.find_all_active(metro_code,include_venues=true)
    places = Place.find_by_sql("select * from places where status='active' order by name")
    sql = <<-SQL 
      select venues.*
       from tourfilter_shared.venues venues,tourfilter_shared.metros_venues mv
       where venues.num_shows>0
       and mv.venue_id=venues.id 
       and mv.metro_code='#{metro_code}'
       group by venues.name
      SQL
    places_hash=Hash.new
    places.each{|place|
      places_hash[place.name]=place
    }
    if include_venues
      venues = Venue.find_by_sql(sql)
      venues.each{|venue|
        if places_hash[venue.name]
          places_hash[venue.name].num_shows="#{places_hash[venue.name].num_shows}+"
        else
          place = PlaceStub.new
          place.name=venue.name
          place.num_shows=venue.num_shows
          places<<place
        end
      }
    end
    places.sort{|x,y|x.name<=>y.name}
  end
  
  def current_matches(num=-1,num_days=180,order_by="date_for_sorting asc")
    if id
      sql = <<-SQL
        (
          select matches.* from matches,places,pages
          where matches.page_id=pages.id and
            pages.place_id=places.id and
            place_id= ? and matches.status='notified' and time_status='future'
            and date_format(date_for_sorting,\"%Y/%m/%d\")>=date_format(now(),\"%Y/%m/%d\") 
            and date_format(date_for_sorting,'%Y/%m/%d')<= 
              date_format(adddate(now(),INTERVAL #{num_days} DAY),'%Y/%m/%d')
            and matches.day is not null
        )
        union
        (
          select matches.* from matches,places
          where matches.venue_id=places.venue_id
            and places.id=?
            and matches.status='notified' and time_status='future'
            and date_format(date_for_sorting,\"%Y/%m/%d\")>=date_format(now(),\"%Y/%m/%d\") 
            and date_format(date_for_sorting,'%Y/%m/%d')<= 
              date_format(adddate(now(),INTERVAL #{num_days} DAY),'%Y/%m/%d')
            and matches.day is not null
        )
        order by #{order_by}
        SQL
      sql +=" limit #{num}" if num!=-1
      return Match.find_by_sql([sql,id,id])
    elsif venue_id
      sql = <<-SQL
        select matches.* from matches
        where matches.venue_id=?
          and matches.status='notified' and time_status='future'
          and date_format(date_for_sorting,\"%Y/%m/%d\")>=date_format(now(),\"%Y/%m/%d\") 
          and date_format(date_for_sorting,'%Y/%m/%d')<= 
            date_format(adddate(now(),INTERVAL #{num_days} DAY),'%Y/%m/%d')
          and matches.day is not null
        order by #{order_by}
        SQL
      sql +=" limit #{num}" if num!=-1
      return Match.find_by_sql([sql,venue_id])
    end
  end         
  
  def matches_within_n_days(num=180,order_by="date_for_sorting asc")
    current_matches(-1,num,order_by)
=begin
    sql = " select matches.* from matches,pages,places" 
    sql +=" where matches.page_id=pages.id and "
    sql +=" pages.place_id=places.id and "
    sql +=" place_id= ? and matches.status='notified' and time_status='future' "
    sql +=" and date_format(date_for_sorting,'%Y/%m/%d')<= "
    sql +="   date_format(adddate(now(),INTERVAL #{num} DAY),'%Y/%m/%d') "
    sql +=" group by matches.term_id "
    sql +=" order by #{order_by}"
    Match.find_by_sql([sql,id])
=end
  end   
  
  def count_matches_within_n_days(num=45)
    sql = " select count(*) from matches,pages,places" 
    sql +=" where matches.page_id=pages.id and "
    sql +=" pages.place_id=places.id and "
    sql +=" place_id= ? and matches.status='notified' and time_status='future' "
    sql +=" and date_format(date_for_sorting,'%Y/%m/%d')<= "
    sql +="   date_format(adddate(now(),INTERVAL #{num} DAY),'%Y/%m/%d') "
    count_1 = Match.count_by_sql([sql,id])
    sql = " select count(*) from matches,places,venues" 
    sql +=" where matches.venue_id=places.venue_id and "
    sql +=" place_id= ? and matches.status='notified' and time_status='future' "
    sql +=" and date_format(date_for_sorting,'%Y/%m/%d')<= "
    sql +="   date_format(adddate(now(),INTERVAL #{num} DAY),'%Y/%m/%d') "
    count_2 = Match.count_by_sql([sql,id])
    count_1+count_2
  end      

  def matches_for_today(num=-1,order_by="date_for_sorting asc")
    sql = " select matches.* from matches,pages,places" 
    sql +=" where matches.page_id=pages.id and "
    sql +=" pages.place_id=places.id and "
    sql +=" place_id= ? and matches.status='notified' and time_status='future' "
    sql +=" and date_format(date_for_sorting,'%Y/%m/%d')=date_format(now(),'%Y/%m/%d')"
    sql +=" group by matches.term_id "
    sql +=" order by #{order_by}"
    sql +=" limit #{num}" if num!=-1
    Match.find_by_sql([sql,id])
  end         

  def count_current()
    sql = " select count(*) from matches,pages,places" 
    sql +=" where matches.page_id=pages.id and "
    sql +=" pages.place_id=places.id and "
    sql +=" place_id=? and matches.status='notified' and time_status='future' "
    sql +=" and date_for_sorting> ? "
    Match.count_by_sql([sql,id,DateTime.now])
  end         

  def recent_matches_for (term,match)
    # any match status whatsoever
    sql = " select matches.* from matches,places,pages" 
    sql +=" where matches.page_id=pages.id and "
    sql +=" pages.place_id=places.id and "
    sql +=" place_id= ? and term_id=? "
    params_array=[id,term.id,2.months.ago]
    if match.day
    # don't bother me with shows that have the same term/place and have recent undated shows at the same place 
      sql += " and ( "
      sql += "      ( "
      sql += "        ((matches.day is null or matches.status='invalid') and matches.created_at> ? )"
      sql += "        or (matches.status='invalid' and (matches.calculated_date_for_sorting=? or matches.date_for_sorting=?))"
      sql += "      ) " 
      sql += "     or " 
      sql += "      ( "
      sql += "       matches.status<>'invalid' "
      sql += "       and (matches.date_for_sorting=? or matches.calculated_date_for_sorting=?) "
      sql += "      ) "
      sql += "     ) " # don't bother me with shows that have the same date/term/place
      params_array<<match.calculated_date_for_sorting
      params_array<<match.calculated_date_for_sorting
      params_array<<match.calculated_date_for_sorting
      params_array<<match.calculated_date_for_sorting
    else
      sql += "and matches.created_at> ? " # for undated shows, just check that there hasn't been a match of any kind in the past 2 months 
    end
    puts sql
    puts "match.calculated_date_for_sorting: #{match.calculated_date_for_sorting}"
    Match.find_by_sql([sql]+params_array)
  end
  
  def pages_as_text=(pages_as_text)
    logger.info("pages_as_text= "+pages_as_text)
    @pages_as_text=pages_as_text
  end
  
  def save_existing_page(line) 
    #begin
      meth = "GET"
      line_portions = line.split(/\s/)
      id=line_portions[0].chomp
      @entered_page_ids[Integer(id)]=true
      url=line_portions[1].chomp
      meth=line_portions[2].chomp if line_portions.size>2
      page = Page.find(id)
      page.url=url
      page.meth=meth
      page.status='future' # innocent until proven guilty
      page.save
    #rescue
      #flash[:error]="error saving urls!"
    #end
  end
  
  def create_new_page(line)
    #begin
      meth = "GET"
      line_portions = line.split(/\s/)
      url=line_portions[0].chomp
      meth=line_portions[1].chomp if line_portions.size>1
      page = Page.new
      page.url=url
      page.meth=meth
      page.status='future' # innocent until proven guilty
      pages<<page
    #rescue
      #flash[:error]="error saving urls!"
    #end
  end

  def mark_all_pages_as_past
    Page.update_all("status='past'",["status='future' and place_id=?",id])
  end

  def delete_template_urls
    Page.delete_all(["url like '%{%' and place_id=?",id])
  end


  def just_save
    @no_before_save=true
    save
  end

  def before_save
    return if @no_before_save
    #agh! this is wrong. we can't delete the pages 
    # cycle through pages_as_text.
    # if there is a number starting it, just save it as that number
    # if there is no number starting it, create it as a new url
    # subtract the list of numbered ones from the list in the database.
    # if there is anything left over, delete it.
     #pages.each {|p| Page.destroy(p.id)}
     @entered_page_ids=Hash.new
     lines_to_save=Array.new
     lines_to_add=Array.new
     @pages_as_text.chomp.split(/[\n]/).each { |line|
      line.chomp!
      if line=~/^\d/ #if the line starts with a number, just save it - it's pre-existing.
        lines_to_save<<line
      else
        lines_to_add<<line
      end
     } if @pages_as_text
     lines_to_save.each{|line|
       save_existing_page(line) 
     }
     # now deal with deleting any deleted pages ...
     pages_to_delete = Array.new
     future_pages.each{ |page|
#       TermsUsers.delete_all(["term_id=? and user_id=?",term.id,id])
#       pages.delete(page)
      if not @entered_page_ids[page.id]
        if page.matches and not page.matches.empty?
          @errors.add"could not delete page '#{page.url(true)}' because it has matches(shows) attached to it"
          next
        end
        Page.delete_all(["id=?",page.id])
        pages_to_delete <<page
      end
     } if future_pages
     pages_to_delete.each{|page|
      if page.matches and not page.matches.empty?
       @errors.add"could not delete page '#{page.url(true)}' because it has matches(shows) attached to it"
       next
      end
      pages.delete(page)
     }
     
     lines_to_add.each{|line|
       create_new_page(line)
     }
  end
  #http://www.wisefoolspub.com/${m}${yyyy}.html
  
  def very_short_time_description
    return nil if time_type!="temporary"
    if SETTINGS['date_type']=='uk'
      return "#{start_date.day}/#{start_date.month} - #{end_date.day}/#{end_date.month}"
    else
      return "#{start_date.month}/#{start_date.day} - #{end_date.month}/#{end_date.day}"
    end
  end

  def short_time_description
    return nil if time_type!="temporary"
    time_descrption(false)
  end

  def time_description(use_preposition=true)
      return nil if time_type!="temporary"
      return nil if not start_date or not end_date
 		  preposition="between " if use_preposition
      if SETTINGS['date_type']=='uk'
		 	  from = "#{start_date.day} #{preposition}#{Date::MONTHNAMES[start_date.month]}"
		 	  to = " and #{end_date.day} #{Date::MONTHNAMES[end_date.month]}"
		 	else
		 	  from = "#{preposition}#{Date::MONTHNAMES[start_date.month]} #{start_date.day}"
		 	  to = " and #{Date::MONTHNAMES[end_date.month]} #{end_date.day}"
		 	end
		 	from+to
  end  
  
  
end
