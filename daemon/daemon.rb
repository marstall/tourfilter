$mode="daemon"
# daemon for tourfilter which:
#   1. loads all urls from the page table
#   2. crawls the value of these urls and puts them into the body column of the page table
#   3. for each user, performs each saved search on all pages in the appropriate metros
#   4. for each match, creates a record in the match table with status of "new"
#   5. when all is complete, for each user, find all new matches, concatenated a report of them
#       and send the report in an email to the user's on-file email address
require "rubygems"
ENV['LOGGING']='no'
#ENV['RAILS_ENV']='production'
require "../config/environment.rb"
require 'rss/1.0'
require 'rss/2.0'
require 'rss/dublincore'
require 'rss/syndication'
require 'rss/content'
require 'rss/trackback'

require "net/http"
require "logger"
require 'open-uri'
=begin
require "../app/models/imported_event.rb"
#require "../app/models/shared_events.rb"
require "../app/models/shared_term.rb"
require "../app/models/metro.rb"
require "../app/models/artist_term.rb"
require "../app/models/ticketmaster_parser.rb"
require "../app/models/terms_users.rb"
require "../app/models/page.rb"
require "../app/models/place.rb"
require "../app/models/match.rb"
require "../app/models/term.rb"
require "../app/models/related_term.rb"
require "../app/models/user.rb"
require "../app/models/event.rb"
require "../app/models/item.rb"
require "../app/models/match_mailer.rb"
require "../app/models/place_image.rb"
require "../app/models/term_url.rb"
require "../app/models/exception_mailer.rb"
require "../app/models/amazon.rb"
require "../app/models/related_terms_manager.rb"
=end

tourfilter_base="http://www.tourfilter.local:3000/boston"
SETTINGS = YAML.load(File.open("../config/settings.yml"))

def initialize_daemon(metro_code)
  SETTINGS['date_type']='us'
  SETTINGS['date_type']='uk' if metro_code=="london" or metro_code=="melbourne" or metro_code=="dublin"
  # setup mail-server configuration params

  rails_env = ENV['RAILS_ENV']
    ActiveRecord::Base.establish_connection(
      :adapter  => "mysql",
      :host     => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['host'],
      :username => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['username'],
      :password => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['password'],
      :database => "tourfilter_#{metro_code}"
      )

=begin
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://www.tourfilter.local:3000/#{metro_code}"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_#{metro_code}",
      :username=>'chris',
      :password=>'chris'
      )
    ActionMailer::Base.smtp_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
#        :address => "tourfilter.com",
#        :domain => "ruby"
    }
  else
    @tourfilter_base="http://www.tourfilter.com/#{metro_code}"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"127.0.0.1",
      :username=>'chris',
      :password=>'chris',
      :database=> "tourfilter_#{metro_code}")
    ActionMailer::Base.smtp_settings = {
      :address => "tourfilter.com",
      :domain => "ruby"
    }
  end
=end
  puts "daemon initialized."
end

def fetch_url(url_text)
  begin
    user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    obj = open(url_text, "User-Agent" => user_agent)
    obj.read
  rescue TimeoutError
    puts "timed out"
  rescue => e
    handle_exception(e)
    puts "exception loading url '#{url_text}': #{$!}"
  end
    
end



#def update_default_listings_pages
#  places = Place.find_all
#  places.each{|place|
#    
#    }
#end

def generate_template_based_urls
  #    generate_template_based_urls
  #    presume all 'template-based' pages have expired, by marking them all as status="past"
  #     then if template-generation results in the recreation of this url, it will be marked as
  #     "future". All searches will be made only on "future" pages, but matches to "past" pages 
  #     will still be valid

  # mark all  'template' rows status='past'
  puts "marking all template-base rows as 'past'"
  Page.update_all("status='past'","flags='template-based'")

  # get a list of all urls with escape sequences
  places = Place.find(:all)
  places.each{|place|
    begin
      puts "checking #{place.name} ... "
      place.generate_urls
    rescue => e
      handle_exception e
    end
    }
end

def perform_crawl
  places = Place.find(:all)
  places.each{|place|
    begin
      puts "fetching urls for #{place.name} ... "
      place.fetch_urls
    rescue => e
      handle_exception e
    end
  }
end # perform_crawl

def expire_match_caches(match)
  return false # don't need to do this anymore with nightly caches
  url="#{@tourfilter_base}/data/expire_match_caches/#{match.id}"
  puts "expiring match caches for term '#{match.term.text}'"
  puts "                  #{url}..."
  result = fetch_url(url)
  puts "                           #{result}"
  result=="success"
end

def perform_searches
  #   3. for each user, perform each saved search on all pages in the 
  #     appropriate metros
  puts "retrieving complete list of terms ..."
terms=Array.new
  if @term_id
    terms = [Term.find(@term_id)]
  elsif @term_text
    terms = [Term.find_by_text(@term_text)]
else
    terms = Term.find(:all,:order =>"text asc") # get all terms
  end
  puts "found #{terms.size} terms"
  if terms.size==1
    puts "working on term #{terms.first.text}"
    puts "marking first term match as 'reevaluating' ... it will have to prove that they are still active."
    terms.first.matches.each{|match|
      match.status='reevaluating' if match.status='future' and not match.imported_event_id.nil?
    }
  else
    puts "marking all future matches as 'reevaluating' ... they will have to prove that they are still active."
    Match.update_all("time_status='reevaluating'","time_status='future' and imported_event_id is null") 
  end
  puts "searching all 'future' urls for all terms..."
  terms.each { |term|
    begin
      puts "finding/creating matches for #{term.text} ..."
      # perform search for the term. if there is a match, put a record in the match table
      Match.search_and_create_matches(term) 
    rescue => e
      handle_exception e
    end
  }
#  Page.report
end

def expire_caches
  # don't have to do this anymore because all former "match" caches get deleted nightly
  # now we must handle matches that still have a time_status of 'reevalutating', meaning they
  # have essentially gone into the past on this running of the daemon. Two things need
  # to happen with them: 
  # One, all caches that depend on them need to be expired.
  # Two, their time_status must be set to past.
  
  # expire caches for matches with time_status = 'reevaluating' and set their time_status to past.
  header "Invalidating caches for any matches that have gone into the past (based on time_status ...)"
  reevaluating_matches = Match.find_all_by_status_and_time_status('notified','reevaluating')
#  reevaluating_matches = Match.find_all_by_time_status('reevaluating')
  reevaluating_matches.each {|match|
    begin
      if expire_match_caches(match)
        match.time_status='past'
        match.save
        puts "match #{match.id}`` saved with time_status='past'"
      end
    rescue => e
      handle_exception e
    end
      
    } if reevaluating_matches
    
    #now see if any matches deserve to be made 'past' because their calculated_date is in the past
    #first, get a list of all 'future' matches with a date_for_sorting that is prior to today
    puts "Invalidating caches for matches that have gone into the past based on the calculated date ..."
    old_matches=Match.find(:all,:conditions => ["date_for_sorting<? and status='notified' and time_status<>'past' and month is not null",Time.now-(24*60*60)]) # matches with valid calculated dates will have non-null month fields
    header "        found #{old_matches.size} matches with old calculated dates" if old_matches
    old_matches.each{ |match|
      begin
      #if match.status!="notified" # if the person has already been notified of this, then the cache has already been invalidated
        if expire_match_caches(match)
          match.time_status="past"
          match.save
        end
      rescue => e
        handle_exception e
      end
      }
      
    # expire the sidebar on the logged-in home page where site-wide recommendations are listed
#    url="#{@tourfilter_base}/data/expire_public_recommendation_caches"
#    puts "expiring public recommendation caches: #{url}"
#    result = fetch_url(url)
#    puts "           ... #{result}"
    

    #expire the public calendar pages
#    url="#{@tourfilter_base}/data/expire_public_calendars_caches"
#    puts "expiring public calendars caches: #{url}"
#    result = fetch_url(url)
#    puts "           ... #{result}"

    #expire the public ical - can't because of need for text/calendar header
    #url="#{@tourfilter_base}/data/expire_ical_pages"
    #puts "expiring public ical cache"
    #result = fetch_url(url)
    #puts "           ... #{result}"

    #expire the public match rss
    #url="#{@tourfilter_base}/data/expire_rss_pages"
    #puts "expiring public rss cache"
    #result = fetch_url(url)
    #puts "           ... #{result}"
end

def is_today(time1)
  time2=Time.now
  time1.day==time2.day and time1.month==time2.month and time1.year==time2.year
end

def perform_deliveries
  #   4. get a list of all new matches (presumably those generated by step 3)
  #   For each match, generate an email to all users who are tracking the term...
  if @id
    puts "retrieving match #{@id} ... " 
    new_matches = [Match.find(@id)]
  else
    puts "retrieving complete list of approved future matches ..."
    new_matches = Match.find(:all, :conditions => "status='approved' and time_status='future' and date_for_sorting>now()")
  end
  
#puts "no new matches found" if new_matches.empty?
  puts "#{new_matches.size} matches found"
  puts "sending #{@num}" if @num 
  MatchMailer.template_root="../app/views"
  MatchMailer.logger=@logger
  new_matches.each_with_index { |match,i|
#puts i
#puts new_matches.size   
break if @num and i>=@num
    begin
      begin
        mail_sent=false  
        no_users_but_valid=false
        users = match.term.users
        puts("Sending individual notification emails for match #{match.term.text}/#{match.page.place.name} to #{users.size} recipients.")
        if (users.size>0)
          if match.onsale_date and is_today(match.onsale_date)
            users.each{|user|
              puts "sending to #{user.email_address} ... "
              MatchMailer::deliver_onsale_match(@metro_code,match,user) 
            }
            puts("                          ... onsale message sent to #{users.size} individual recipients!")
          else
            puts "normal match"
            users.each{|user|
              puts "sending to #{user.email_address} ... "
              email = MatchMailer::deliver_match(@metro_code,match,user) 
            }
            puts("                          ... normal message sent to #{users.size} individual recipients!")
          end
          mail_sent=true
          #expire_match_caches(match) unless @dry_run
        else
          no_users_but_valid=true
          puts "skipping match, term '#{match.term.text}' has no users!"
        end
        unless @dry_run
          if mail_sent or no_users_but_valid
            match.status="notified" # mark the match as notified so that mails for it won't go out again
            Event.match_email_created(match) unless @dry_run
            match.save
            puts("                          ... match row updated!")
          end
        end
#      rescue
#        puts "error mailing - message not sent, row not updated!"
#        puts $!
      end
      #puts email
  
    rescue => e
  handle_exception e
    end
  } 
  #expire the terms by place list again, to account for matches that may have been invalidated
  #url="#{@tourfilter_base}/data/expire_terms_by_place_cache"
  #puts "expiring terms by place cache"
  #result = fetch_url(url)
  #puts "           ... #{result}"
  
end

def update_match_times
  Match.find_all("time_status='future' and (status='new' or status='notified' or status='approved')").each{|match|
    begin
      match.year=nil
      match.month=nil
      match.day=nil
      match.date_for_sorting=nil
      match.calculate_date_of_event
      match.save
      puts "#{match.term.text} at #{match.page.place.name} #{match.time_description} [page=#{match.page.id}]"
    rescue => e
      handle_exception e
    end
  }
end

def generate_related_terms
  RelatedTerm.delete_all("true")
  all_terms= Term.all_alpha
  all_terms.each_with_index{|term,i|
    term.generate_related_terms
    puts "#{i}/#{all_terms.size}\t#{term.text}"
  }
end 

def do_played_with_stuff
  clear_and_generate_played_with_scores
end

def process_images
  images = Image.find_unprocessed_images
#  images = [Image.find_by_term_text("alloy orchestra")]
  puts "found #{images.size} unprocessed images. processing ..."
  images.each{|image|
    puts "processing image #{image.term_text} ..."
    begin
      image.process
    rescue
      puts "+++ error ... image marked as 'problem' image, continuing ..."
      image.problem='yes'
      image.save
    end
  }
end
=begin
CREATE TABLE `term_words` (
  `id` int(11) NOT NULL auto_increment,
  `term_text` int(11),
  `word` varchar(255) NOT NULL,
  `source` char(16),
  `created_at` datetime,
  `tweet_id` int(11),
  PRIMARY KEY  (`id`)
)

CREATE TABLE `tweets` (
  `id` int(11) NOT NULL auto_increment,
  `guid` int(11) ,
  `term_text` int(11),
  `date` datetime,
  `text` varchar(255) NOT NULL,
  `author` text NOT NULL,
  `created_at` datetime,
  PRIMARY KEY  (`id`)
)
=end

def do_twitter_stuff
  shared_events = SharedEvent.find_all_unique(@operating_metro_code)
  puts "found #{shared_events.size} shared_events ... processing"
  shared_events.each{|shared_event|
    summary = shared_event.summary.strip
    search_term = "%20#{summary.gsub(' ','+')}%20+concert"
    url = "http://search.twitter.com/search.rss?q=#{search_term}"
     begin
        rss_source = fetch_url(url)
        rss = RSS::Parser.parse(rss_source,false)
      rss.items.each{|item|
        puts "                            "+item.title
        tweet=Tweet.new
        tweet.guid=item.guid.content
        puts "term_text: #{summary}"
        tweet.term_text=summary
        tweet.text=item.title
        tweet.date=item.pubDate.to_s
        tweet.author=item.author
        begin
          tweet.save
        rescue
          puts "dupe tweet..."
          next
        end
        #tweet.generate_term_words 
      }
      rescue => e
        puts e
        next
      rescue TimeoutError
        puts $!
        next
      end
  }
end

def find_term_urls
  find_urls_in_place_pages
#  find_urls_via_google
end

def search_for_urls
  # use google to find the myspace page for bands that (1) have an upcoming show and (2) don't already have a url. should just be a few!
  terms = Term.find_all_with_upcoming_show_and_no_url
  terms.each{|term|
    term.find_and_save_myspace_url
  }
end

def find_urls_in_place_pages
  if @place_id
    places = [Place.find(@place_id)]
  elsif @place_name
    places = Place.find_by_sql("select * from places where name like \"%#{@place_name}%\"")
  else
    places = Place.find_all_active(@metro_code)
  end
  puts "found #{places.size} places. (place_name: #{@place_name}) (place_id: #{@place_id})"
  places.each{|place|
    puts "processing place #{place.name}"
    place.process_urls
  }
end

def find_place_images
  if @place_id
    places = [Place.find(@place_id)]
  elsif @place_name
    places = Place.find_by_sql("select * from places where name like \"%#{@place_name}%\"")
  else
    places = Place.find_all_active(@metro_code)
  end
  puts "found #{places.size} places. (place_name: #{@place_name}) (place_id: #{@place_id})"
  places.each{|place|
    puts "processing place #{place.name}"
    place.process_images
  }
end

def update_place_counts
  sql =  <<-SQL
    select places.id,places.name,count(*) num_shows from places,pages,matches 
    where pages.place_id=places.id and matches.page_id=pages.id 
    and matches.status='notified' and matches.time_status='future' and matches.date_for_sorting>now()
    and matches.day is not null
    group by place_id order by places.name 
  SQL
  places = Place.find_by_sql(sql)
  places.each{|place|
    puts "#{place.name}:#{place.num_shows}"
    place.just_save # no before_save
  }
  puts "done."
end

def update_aggregate_num_trackers
  metros=Metro.find_all
  SharedTerm.find(:all,:order=>'text',:limit=>100000).each{|st|
    next if st.text=~/\"/
    total_trackers=0
    terms_to_update=Hash.new
    metros.each_with_index{|metro,i|
#      next unless metro.code=='boston' or metro.code=='newyork'
        sql="select * from tourfilter_#{metro.code}.terms where text=\""+st.text+"\""
        terms = Term.find_by_sql(sql) rescue next
        term=terms.first
        if term
          total_trackers+=term.num_trackers.to_i if term.num_trackers
          terms_to_update[metro.code]=term
        end
    }
    puts "#{st.text}: #{total_trackers}" if total_trackers>0
    st.num_trackers=total_trackers
    st.save
    terms_to_update.each_key{|metro_code|
      term=terms_to_update[metro_code]
      term.aggregate_num_trackers=total_trackers
          ActiveRecord::Base.connection.execute("update tourfilter_#{metro_code}.terms set aggregate_num_trackers=#{total_trackers} where id=#{term.id}")
      }
    }
end

def update_num_trackers
  puts "updating num_trackers"
  Term.find(:all,:order=>'text').each{|term|
    num_trackers=term.calculate_num_trackers
    if term.text=~/^the/i
      term2=Term.find_by_text(term.text.gsub(/^the/,"").strip)
      num_trackers+=term2.calculate_num_trackers if term2
    else
      term2=Term.find_by_text("the #{term.text}")
      num_trackers+=term2.calculate_num_trackers if term2
    end
    term.num_trackers=num_trackers
    term.save
    puts "#{term.text}:#{term.num_trackers}"
    }
end

def update_venue_counts
  puts "updating venue counts ..."
  sql = <<-SQL
    select venues.*,count(*) num_shows
     from tourfilter_shared.venues venues,
     tourfilter_shared.imported_events ie
     where ie.date>now()
     and ie.venue_id=venues.id
     and ie.status='made_match' and ie.date>now() 
     group by venues.name
  SQL
  venues = Venue.find_by_sql(sql)
  puts "found #{venues.size} venues" 
  venues.each{|venue|
    puts "#{venue.name}:#{venue.num_shows}"
    venue.save # no before_save
  }
  puts "done."
end

def header (s)
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end

def do_amazon_stuff(fast_forward=false,refresh=false)
  Amazon.do_stuff(fast_forward,refresh)
  puts "done with amazon stuff"
end

def precache
  return
  begin
  @tourfilter_base="http://www.tourfilter.com/#{@metro_code}"
  # loop through all matches. for each:
  #   hit term_more_info page up
  #   hit band page up
  precached=Hash.new
  matches = Match.current
  url="#{@tourfilter_base}/edit/venues_partial"
  puts "precaching #{url}"
  fetch_url(url)
  url="#{@tourfilter_base}/edit/calendar_partial"
  puts "precaching #{url}"
  fetch_url(url)
  rescue 
  end
 
  matches.each_with_index{|match,i|
    begin
      term = match.term
      term_text= term.text
      next if precached[term_text]
      precached[term_text]=true
      puts "[#{i}/#{matches.size}] #{term_text.downcase}, #{match.page.place.name.downcase}, #{match.very_short_time_description}"
      url="#{@tourfilter_base}/edit/term_more_info_popup/#{match.id}"
#      puts url
      fetch_url(url)
      url="#{@tourfilter_base}/#{term.url_text}"
#      puts url
      fetch_url(url)
    rescue
    end
    }
end

def lastfm_sync
  lastfm=Lastfm.new(@logger)
  sql= "select * from users where lastfm_username is not null"
  users = User.find_by_sql(sql)
  users.each{|user|
      puts user.name+":"+user.lastfm_username
      names = lastfm.import(user)
      puts names.join(", ")
    }
end

def main(args)
  begin
    _generate_template_based_urls = false;
    _perform_searches = false;
    _expire_caches = false;
    _perform_deliveries = false;
    _perform_crawl=false
    _update_match_times = false;
    _generate_related_terms = false;
    _do_played_with_stuff = false;
    _find_term_urls=false
    _find_place_images=false
    _update_place_counts=false
    _update_venue_counts=false
    _update_num_trackers=false
    _update_aggregate_num_trackers=false
    _precache=false
    _lastfm_sync=false
    _do_amazon_stuff=false
    _process_images=false
    _do_twitter_stuff=false
    @fast_forward=false
    @dry_run=false
    @refresh=false
    @num=nil
    @metro_code = args[0]
    _generate_template_based_urls=true if args.index("generate_urls")
    _perform_searches=true if args.index("search")
    _expire_caches=true if args.index("expire_caches")
    _perform_deliveries=true if args.index("send_email")
    _perform_crawl=true if args.index("crawl")
    _update_match_times=true if args.index("update_match_times")
    _generate_related_terms=true if args.index("generate_related_terms")
    _do_played_with_stuff=true if args.index("do_played_with_stuff")
    _find_term_urls=true if args.index("find_term_urls")
    _find_place_images=true if args.index("find_place_images")
    _update_place_counts=true if args.index("update_place_counts")
    _update_venue_counts=true if args.index("update_venue_counts")
    _update_num_trackers=true if args.index("update_num_trackers")
    _update_aggregate_num_trackers=true if args.index("update_aggregate_num_trackers")
    _precache=true if args.index("precache")
    _do_amazon_stuff=true if args.index("do_amazon_stuff")
    _process_images=true if args.index("process_images")
    _lastfm_sync=true if args.index("lastfm_sync")
    _do_twitter_stuff=true if args.index("do_twitter_stuff")
    if _do_amazon_stuff or _process_images or _do_twitter_stuff or _update_aggregate_num_trackers
      @operating_metro_code=@metro_code
      @metro_code = "shared"   
    end
    @term_id=args[args.size-1] if args.index("term_id")
    @id=args[args.size-1] if args.index("id")
    @num=Integer(args[args.size-1]) if args.index("num")
    @place_id=args[args.size-1] if args.index("place_id")
    @place_name=args[args.size-1] if args.index("place")
    @term_text=args[args.size-1] if args.index("term")
    @fast_forward=true if args.index("fast-forward")
    @refresh=true if args.index("refresh")
    @dry_run=true if args.index("dry-run")

    @logger = Logger.new("daemon.log")
    @logger.level = Logger::DEBUG

    #place_id_index = args.index("place_id")
    #place_id = args.index(place_id_index+1)

    header "running on metro #{@metro_code}!"
    initialize_daemon(@metro_code)
    if (_process_images) 
      header "processing band images"
      process_images
    end
    if (_do_twitter_stuff) 
      header "doing twitter stuff"
      do_twitter_stuff
    end
    if (_generate_template_based_urls) 
      header "generating template-based urls"
      generate_template_based_urls
    end
    if (_perform_crawl) 
      header "starting crawl"
      perform_crawl
    end
    if (_perform_searches) 
      header "starting searches"
      perform_searches
    end
    if (_perform_deliveries) 
      header "sending email"
      perform_deliveries
    end
    if (_expire_caches) 
      header "starting cache expiry"
      expire_caches
    end
    if (_update_match_times) 
      header "updating match times"
      update_match_times
    end
    if (_generate_related_terms) 
      header "generating related terms"
      generate_related_terms
    end
    if (_do_played_with_stuff) 
      header "doing played with stuff"
      do_played_with_stuff
    end
    if (_find_term_urls) 
      header "finding term urls"
      find_term_urls
    end
    if (_find_place_images) 
      header "finding place images"
      find_place_images
    end
    if (_update_place_counts) 
      header "updating place counts"
      update_place_counts
    end
    if (_update_venue_counts) 
      header "updating venue counts"
      update_venue_counts
    end
    if (_do_amazon_stuff) 
      header "doing amazon stuff"
      do_amazon_stuff
    end
    if (_update_num_trackers) 
      header "updating num_trackers"
      update_num_trackers
    end
    if (_update_aggregate_num_trackers) 
      header "updating aggregate num_trackers"
      update_aggregate_num_trackers
    end
    if (_precache) 
      header "precaching"
      precache
    end
    if (_lastfm_sync) 
      header "syncing last.fm"
      lastfm_sync
    end

  rescue => e
    handle_exception e
  end
end

def handle_exception (e)
begin
  puts e if e
  puts e.backtrace.join("\n") if e
  ExceptionMailer.logger=@logger
  ExceptionMailer.template_root="../app/views"
  ExceptionMailer::deliver_snapshot("#{@metro_code} daemon",e) 
rescue =>e
  puts "error handling exception ("+e.to_s+")"
rescue Timeout::Error
end
end

#  ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['RAILS_ENV']!="production"

# program entry point
puts "#{ENV[RAILS_ENV]} mode"
if (!ARGV.index("help").nil? or ARGV.empty?)
  puts " Daemon: generates template-based urls, crawls, searches, sends emails and expires caches"
  puts "Usage: ruby daemon.rb metro_code [generate_urls] [search] [expire_caches] [send_email] [crawl] [lastfm_sync]"
  puts " [update_match_times] [generate_related_terms] [do_played_with_stuff][find_term_urls] [update_num_trackers] [update_aggregate_num_trackers]"
  puts " [find_place_images] [update_venue_counts] [update_place_counts] [do_amazon_stuff] [process_images] [do_twitter_stuff] [precache]"
  puts " [help] [place_id|place|term|term_id|id n] [num n] [fast-forward] [refresh] [dry-run]"
  puts "Author: chris marstall Dec 2005 - May 2009"
  exit
else
  puts "for usage: ruby daemon.rb help"
end
main(ARGV)
