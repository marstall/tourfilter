$mode='import_daemon'

# daemon for tourfilter which:
#   1. loads all urls from the page table
#   2. crawls the value of these urls and puts them into the body column of the page table
#   3. for each user, performs each saved search on all pages in the appropriate metros
#   4. for each match, creates a record in the match table with status of "new"
#   5. when all is complete, for each user, find all new matches, concatenated a report of them
#       and send the report in an email to the user's on-file email address
require "rubygems"
require "../config/environment.rb"
require 'mechanize'
require "net/http"
require "logger"
require "hpricot"
require 'open-uri'
require 'uri'
require 'text'
#begin
#gem "activerecord"
#require "active_record"
#rescue
#require "activerecord"
#end

#begin
#gem "actionmailer" 
#require "action_mailer"
#rescue
#require "actionmailer"
#end

#require "../app/models/parser.rb"
require "../app/models/imported_event.rb"
#require "../app/models/shared_events.rb"
require "../app/models/shared_term.rb"
require "../app/models/metro.rb"
require "../app/models/artist_term.rb"
require "ticketmaster_parser.rb"
#require "stubhub_parser.rb"
$KCODE='u' 
require 'jcode' 

def connect_to_database(metro_code)
  ActiveRecord::Base.establish_connection(
    :adapter  => "mysql",
    :host     => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['host'],
    :username => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['username'],
    :password => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['password'],
    :database => "tourfilter_#{metro_code}"
    )
end

def initialize_daemon_(metro_code=nil)
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
#  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://www.antiplex.local:3000/"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_#{metro_code||'shared'}",
      :username=>'chris',
      :encoding=>'utf8',
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
    @tourfilter_base="http://www.tourfilter.com/"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"127.0.0.1",
      :username=>'chris',
      :password=>'chris',
      :encoding=>'utf8',
      :database=> "tourfilter_#{metro_code||'shared'}"
      )
    ActionMailer::Base.smtp_settings = {
      :address => "tourfilter.com",
      :domain => "ruby"
    }
  end
end

def fetch_url(url_text)
  begin
    user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    obj = open(url_text, "User-Agent" => user_agent)
    obj.read
  rescue => e
    handle_exception(e)
    puts "exception loading url '#{url_text}': #{$!}"
  end
    
end
begin
  require '/usr/local/lib/ruby/gems/1.8/gems/mechanize-0.7.0/lib/www/mechanize.rb'
rescue MissingSourceFile
end
require  'mechanize'


def find_valid_urls
  puts "finding valid urls for ticketmaster ... "
  TicketmasterParser.new.find_valid_urls
end


# will either return the number of ms it took to load num_bytes_required bytes, or throw an exception.
# follows any redirections (up to 5)
 def get_final_url(uri_str,limit=5)
#   puts "getting final url for #{uri_str} ... "
      if limit==0
        puts "HTTP redirect too deep"
      end
      uri = URI.parse(uri_str)
#      raise ArgumentError, 'HTTP redirect too deep' if limit == 0
      response=Object.new
      begin
        timeout(7) do
            Net::HTTP.start(uri.host) {|http|
              response = http.request_head(uri.path)
              case response
                when Net::HTTPSuccess     then 
#                  puts "\t\t\t\t\t\t\t\t\t\t!!!success"
                  response
                when Net::HTTPRedirection then 
                  puts "redirecting to #{response['location']}"
                  uri_str = get_final_url(response['location'].gsub(/\s/,"%20"), limit - 1)
                else
                  response.error!
                end
            }
#          puts "response headers:"
          response.each_key{|key|
#            puts "#{key}: #{response[key]}"
          }
        end
    rescue TimeoutError
      puts "\t\t\t\t\t\t\t\t\t\t???timed out"
    rescue => e
      puts "\t\t\t\t\t\t\t\t\t\t???#{e}"
    end
#    puts "returning #{uri_str} from get_final_url"
    uri_str
 end
 
  def time_start
    @time = Time.now.to_f    
  end
  
  def time_end
    "#{(Time.now.to_f-@time)*1000000}"  
  end

public
def search
  if @term_text
    shared_terms=[SharedTerm.find_by_text(@term_text)]
  else
    shared_terms=SharedTerm.find(:all,:order=>:text)    
  end
  puts "searching for #{shared_terms.size} term(s) ..."
  imported_event = ImportedEvent.new
  imported_events = imported_event.search("=","find_all_by_status","new")
  shared_terms.each_with_index{|term,i|
      time_start
      imported_events = imported_event.search(term.text)

      puts "#{term.text}: #{(imported_events||[]).size} matches" 
      imported_events.each{|event|
        at = ArtistTerm.find_by_artist_name_and_term_text_and_status(term.text,event.body,'invalid')
        if at
          puts "found invalid at like this (#{at.id}:#{at.status})"
          next
        end
        # mark event as found
        event.status='term_found'
        event.save
        artist_term = ArtistTerm.new
        artist_term.imported_event_id=event.id
        artist_term.artist_name=event.body
        artist_term.term_text=term.text
        artist_term.status='new'
        pref="   "
        begin
          artist_term.calculate_match_probability
          artist_term.save 
          pref="+++"
        rescue => e
          puts e
        end
        puts "#{pref} [#{term.text}]\t\t#{imported_event.body} (#{i} of #{shared_terms.size})"
      } if imported_events
#      puts time_end
  }
  # now mark all new imported_events as "no_term_found"
  puts "marking remainder as 'no_term_found'"
  ImportedEvent.update_all("status='no_term_found'","status='new'")
end

def assign_match_probability
  if @term_text
    artist_terms=ArtistTerm.find_all_by_term_text(@term_text)
  else
    artist_terms=ArtistTerm.find_all_by_match_probability_and_status("undetermined","new")    
  end
  puts "assigning match probability to #{artist_terms.size} artist_terms records"
  num_positives=0
  artist_terms.each{|at|  
    result = at.calculate_match_probability
    if result
      puts "#{result||'unlkly'}\t[#{at.term_text}] #{at.artist_name}" 
      num_positives+=1
    end
    at.save
  }
  puts "found #{num_positives}/#{artist_terms.size} likely matches."
end 

def geocode_venues_test
  venues = Venue.find_by_sql(
    <<-SQL 
    select venues.* from venues
    where  lat is null and venues.city is not null and venues.state is not null and length(city)>0 and length(state)>0
    and venues.source='ticketmaster_uk'
    group by venues.name,city,state order by venues.name
    SQL
    )
  puts "found #{venues.size} venues. processing ..."
  venues.each_with_index{|venue,i|
#    break if i>1000
    puts "#{i} of #{venues.size}"
    venue.geocode
  }
end


def geocode_venues
  venues = Venue.find_by_sql(
    <<-SQL 
    select venues.* from venues,imported_events 
    where venues.id=imported_events.venue_id and lat is null and venues.city is not null and venues.state is not null and length(city)>0 and length(state)>0
    group by venues.name,city,state order by venues.name
    SQL
    )
  puts "found #{venues.size} venues. processing ..."
  venues.each_with_index{|venue,i|
#    break if i>1000
    puts "#{i} of #{venues.size}"
    venue.geocode
  }
end


def put_venues_in_metros
  if @country_code
    puts "restricting to country code '#{@country_code}'"
    metros = Metro.find_all_by_country_code(@country_code)
  else
    metros = Metro.find(:all)
  end
  puts "found #{metros.size} metros"
  metros.each{|metro|
    puts "+++ #{metro.code} +++"
    venues = Venue.find_near_metro_by_geocoding(metro)
    if venues
      puts "[#{metro.code}] #{venues.size} venues."
    else
      puts "[#{metro.code}] error (nil result)."
      next
    end
    venues.each{|venue|
      venue.metros="#{venue.metros||''} #{metro.code}"
      venue.save
      puts "#{venue.name} [#{venue.metros}]"
      mv=MetrosVenue.new
      mv.venue_id=venue.id
      mv.metro_code=metro.code
      begin
        mv.save 
      rescue
        puts "dupe, skipping ..."
      end
#      puts "#{venue.name} (#{venue.city}, #{venue.state}) is in metro #{metro.name}"
    }
  }
end

def geocode_metros
  Metro.find(:all).each{|metro|
    res = MultiGeocoder.geocode("#{metro.name},#{metro.state}")
    if not res.nil?
      metro.zipcode=res.zip
      metro.lat=res.lat
      metro.lng=res.lng
      metro.save
    else
      puts "nil response"
    end
    puts "#{metro.name} #{metro.zipcode} #{metro.lat} #{metro.lng}"    
  }
end

def normalize(name)
  name=name.downcase
  name=name.strip
  name=name.gsub(/(^the|of|and|[^A-Za-z])/,"")
  name
end

# ok this needs to change ... new logic is
# get all valid imported_events rows. for each,
# check in the metro.matches table for a match with the same term and date
# if FOUND
#   create a new imported_event_match record linking this imported_event with the matc
# if NOT FOUND
#   create a new match for this row, pointed directly to the imported_event and venue, 
#   with a status of 'approved' 
=begin
    update imported events,venues set imported_events.status='term_found' where imported_events.status='made_match'
    and venue_id=venues.id and venues.metros like "%manchester%";
    select at.term_text,v.name,ie.* 
    from tourfilter_shared.imported_events ie,tourfilter_shared.artist_terms at,tourfilter_shared.metros_venues mv,tourfilter_shared.venues v
    where at.imported_event_id=ie.id
    and ie.status='made_match'
    and at.status='valid'
    and mv.venue_id=ie.venue_id
    and ie.venue_id=v.id
    and mv.metro_code='manchester'
    and mv.status='valid'
=end

def make_matches_from_imported_events
  raise Exception.new("must specify metro_code") unless @metro_code
  shared_db_name="tourfilter_shared"  
  source_sql=""
  if @source
    source_sql=" and ie.source='#{@source}' " 
    puts "restricting to events from source <#{@source}> only"
  end
  # get all imported_events w/ term_text they match
  sql = <<-SQL
    select at.term_text,v.name,ie.* 
    from #{shared_db_name}.imported_events ie,#{shared_db_name}.artist_terms at,#{shared_db_name}.metros_venues mv,#{shared_db_name}.venues v
    where at.imported_event_id=ie.id
    and ie.status='term_found'
    and at.status='valid'
    and mv.venue_id=ie.venue_id
    and ie.venue_id=v.id
    and mv.metro_code='#{@metro_code}'
    and mv.status='valid'
	and ie.date>now()     
#{source_sql}
  SQL
#  puts sql
  imported_events = Place.find_by_sql(sql)
  puts "found #{imported_events.size} imported_events in metro #{@metro_code}"
  imported_events.each{|event|
    puts "[#{event.term_text} #{event.date.to_date.month rescue '?'}/#{event.date.to_date.day rescue '?'}]"
    next unless event.date # skip any with nil dates
    # ok, find uid dupes
    uid ="#{event.term_text}_#{event.id}"
    puts "searching for uid #{uid}"
    if Match.find_by_uid(uid)
      puts "imported_event.id dupe: skipped. "
      next
    else
      puts "uid not found"
    end
    matches = Match.find_dupes_by_term_and_date(event.term_text,event.date)
    puts "found #{matches.size} dupes."
    if matches and not matches.empty?
      # ok there is already a match for this date and term. leave it alone, just create a 
      # link between the imported_event and the match
      iem = ImportedEventsMatch.new
      match = matches.first
      iem.match_id=match.id
      iem.imported_event_id=event.id
      iem.description="#{event.source}_#{(event.venue_name||'?')[0..16]}_#{event.term_text[0..16]}_#{match.month}.#{match.day}.#{match.year}"
      begin
        iem.save
      rescue
        finalize_imported_event(event)
        puts "already linked this match with this imported_event, skipping to next imported_event"
        next
      end
      puts "--- existing match found, created new iem row"
    else
      # no existing match, so create a new one.
      term = Term.find_by_text(event.term_text) # first find the term we're dealing with
      if not term or not term.id
        puts "not term"
	puts "term_text"+event.term_text      
  term = Term.new
        term.text=event.term_text 
        term.save # create a new term with this text if it doesn't exist
      end
     
	if not term.id
		puts "mysteriously, no term.id"
		next
end	
match=Match.new
      match.venue_id=event.venue_id
      match.venue_name=event.name
      match.imported_event_id=event.id
      match.term_id=term.id 
      match.status='approved'
      match.time_status='future'
      match.user_id=event.user_id
      match.source=event.source
      match.onsale_date=event.onsale_date
      match.presale_date=event.presale_date
      if event.date
        match.year=event.date.to_date.year
        match.month=event.date.to_date.month
        match.day=event.date.to_date.day
      end
      match.date_for_sorting=event.date
      match.uid=uid
      match.save    
      puts "+++ no dupes found, creating new match row with uid #{uid}"
    end
    finalize_imported_event(event)
  }
#  paint_remaining_events_as_rejected
end    

def finalize_imported_event(event)
  connect_to_database("shared")
  ImportedEvent.update_all("status='made_match'","id=#{event.id}")
  connect_to_database @metro_code
end

def mark_remaining_events_as_rejected
  connect_to_database("shared")
  ImportedEvent.update_all("status='rejected'","status='term_found'")
  connect_to_database @metro_code
  end

def make_matches_from_imported_events_old
  raise Exception.new("must specify metro_code") unless @metro_code
  shared_db_name="tourfilter_shared"  
  sql = <<-SQL
    select at.term_text,v.name,ie.* 
    from #{shared_db_name}.imported_events ie,#{shared_db_name}.artist_terms at,#{shared_db_name}.metros_venues mv,#{shared_db_name}.venues v
    where at.artist_name=ie.body
    and at.status='valid'
    and (ie.status<>'processed' or ie.status is null)
    and mv.venue_id=ie.venue_id
    and ie.venue_id=v.id
    and mv.metro_code='#{@metro_code}'
  SQL
  imported_events = Place.find_by_sql(sql)
  puts "found #{imported_events.size} imported_events in metro #{@metro_code}"
  imported_events.each{|event|
    next unless event.date # skip any with nil dates
    # ok, find uid dupes
    if Match.find_by_uid("#{event.term_text}_#{event.id}")
      puts "ie id dupe\t[#{event.term_text} #{event.date.to_date.month rescue '?'}/#{event.date.to_date.day rescue '?'}]: skipped. (imported_event_id: #{event.id})"
      next
    end
    # find dupes
    dupe_matches = Match.find_dupes_by_term_and_venue_id(event.term_text,event.venue_id)
    # invalidate dupes
    new_match_status='approved' # presumption that people will be notified
    dupe_matches.each{|match|
      match.replaced_with_imported_event_id=event.id
      # since this event already exists in the database, don't mark new match as 'approved',
      # (meaning emails will go out), unless there is a date correction or the existing dupe was 'approved', 
      # so no notification had gone out. 
      unless (event.date.to_date.month!=match.date_for_sorting.month) and (event.date.to_date.day!=match.date_for_sorting.day)
        new_match_status=match.status
      end
#      puts "new_match_status: #{new_match_status}"
      match.status='invalid'
      match.save
    }
    # dupes dealt with, create a new match
    term = Term.find_by_text(event.term_text) # first find the term we're dealing with
    if not term
      term = Term.new
      term.text=event.term_text 
      term.save # create a new term with this text if it doesn't exist
    end
    match=Match.new
    match.venue_id=event.venue_id
    match.venue_name=event.name
    match.imported_event_id=event.id
    match.term_id=term.id
    match.status=new_match_status
    match.time_status='future'
    if event.date
      match.year=event.date.to_date.year
      match.month=event.date.to_date.month
      match.day=event.date.to_date.day
    end
    match.date_for_sorting=event.date
    match.uid="#{event.term_text}_#{event.id}"
    match.save
    if dupe_matches and not dupe_matches.empty?
        dupe_matches.each{|_match|
        same_token="+++"
        same_token="---" if (event.date.to_date.month!=_match.date_for_sorting.month) and (event.date.to_date.day!=_match.date_for_sorting.day)
        puts "#{same_token} dupe\t[#{event.term_text} at #{event.name.downcase} on #{event.date.to_date.month}/#{event.date.to_date.day}]: #{_match.term.text} at #{_match.page.place.name.downcase} on #{_match.month}/#{_match.day} (status #{match.status})"
        }
    else
      puts "imported\t[#{event.term_text} at #{event.name.downcase} on #{event.date.to_date.month rescue '?'}/#{event.date.to_date.day rescue '?'}]: match id #{match.id} (status #{match.status})"
    end
    # now update the event as processed.
#     Place.find_by_sql("update #{shared_db_name}.imported_events set status  ='processed' where id=#{event.id}")
  }
end

def link_places_to_venues
  raise Exception.new("must specify metro_code") unless @metro_code
  Place.find(:all).each{|place|
    venues = Place.find_by_sql <<-SQL
      select v.* from tourfilter_shared.venues v, tourfilter_shared.metros_venues mv 
      where mv.venue_id=v.id 
      and mv.metro_code='#{@metro_code}'
    SQL
    venues.each{|venue|
      place_name = normalize(place.name)
      venue_name = normalize(venue.name)
      distance = Text::Levenshtein.distance(place_name,venue_name)
      if distance<place_name.length/2 and distance<(place.venue_name_distance||100)
        puts "#{place.name} (#{place.num_shows||0})\t\t#{venue.name} (#{venue.events_last_imported||0})\t\t#{distance}/#{place_name.length}" 
        place.venue_id=venue.id
        place.venue_name=venue.name
        place.venue_name_distance=distance
        place.save
      end
    }

  }
  Place.find_by_sql("select * from places where venue_id is not null").each{|place|
      puts "#{place.name} (#{place.num_shows||0})\t\t#{place.venue_name} #{place.venue_name_distance}" 
  }
end

def find_metro_zips
  puts "here"
  Metro.find(:all).each{|metro|
    next unless metro.zipcode.nil?
    zip = Metro.find_by_sql <<-SQL 
      select zips.zip,zips.lat,zips.lng  
      from zips,metros where zips.name=metros.name 
      and zips.state=metros.state 
      and metros.name='#{metro.name}' limit 1
      SQL
    if zip and zip.first
      lat = zip.first['lat'].to_s
      lng = zip.first['lng'].to_s
      zip = zip.first.zip
      metro.lat=lat
      metro.zipcode=zip
      metro.lng=lng
      metro.save
      puts "#{metro.name} #{zip} #{lat} #{lng}"
    end
  }
end
 
def header (s)
  return unless s
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end

def main(args)
  begin
    _import_ticketmaster_tickets=false
    _import_ticketmaster_uk_tickets=false
    _import_ticketnetwork_tickets=false
    _import_stubhub_tickets=false
    _import_ticketsnow_tickets=false
    _import_ticketmaster_us_venues_from_file=false
    _search=false
    _find_valid_urls=false
    _find_metro_zips=false
    _geocode_venues=false
    _geocode_metros=false
    _put_venues_in_metros=false
    _link_places_to_venues=false
    _make_matches_from_imported_events=false
    _assign_match_probability=false
    @fast_forward=false
    @fast_forward=true if args.index("fast-forward")
    $debug = false;
    _url = nil
    _import_ticketmaster_tickets=true if args.index("import_ticketmaster_tickets")
    _import_ticketmaster_uk_tickets=true if args.index("import_ticketmaster_uk_tickets")
    _import_ticketnetwork_tickets=true if args.index("import_ticketnetwork_tickets")
    _import_ticketsnow_tickets=true if args.index("import_ticketsnow_tickets")
    _search=true if args.index("search")
    _find_metro_zips=true if args.index("find_metro_zips") 
    _geocode_venues=true if args.index("geocode_venues") 
    _geocode_metros=true if args.index("geocode_metros") 
    _put_venues_in_metros=true if args.index("put_venues_in_metros") 
    _link_places_to_venues=true if args.index("link_places_to_venues") 
    _make_matches_from_imported_events=true if args.index("make_matches_from_imported_events") 
    _assign_match_probability=true if args.index("assign_match_probability") 
    _import_ticketmaster_us_venues_from_file=true if args.index("import_ticketmaster_us_venues_from_file")
    _import_stubhub_tickets=true if args.index("import_stubhub_tickets")
    _mark_remaining_events_as_rejected=true if args.index("mark_remaining_events_as_rejected")
    $debug=true if args.index("debug")
    @place_name=args[args.size-1] if args.index("place")
    @logger = Logger.new("daemon.log")
    @logger.level = Logger::DEBUG
    file_name=args[args.size-1] if args.index("import_ticketmaster_us_venues_from_file")
    @code=args[args.size-1] if args.index("code")
    @term_text=args[args.size-1] if args.index("term")
    @source=nil
    @source=args[args.index("source")+1] if args.index("source")
    @country_code=args[args.index("country_code")+1] if args.index("country_code")
    @metro_code=args[args.index("metro")+1] if args.index("metro")
    connect_to_database(@metro_code)
    if (_import_ticketmaster_us_venues_from_file) 
      header "importing ticketmaster US venues from file"
      TicketmasterParser.new.import_venues_from_file("US",file_name)
    end
    if (_import_stubhub_tickets)
      header "importing stubhub ticket infomation"
      StubhubParser.new.crawl(@code,@fast_forward)
    end
    if (_mark_remaining_events_as_rejected) 
      header "marking all events with status of 'term_found' with status of 'rejected'"
      mark_remaining_events_as_rejected      
    end
    if (_import_ticketmaster_tickets) 
      header "importing ticketmaster tickets"
        TicketmasterParser.new.crawl(@code,@fast_forward)
    end
    if (_import_ticketmaster_uk_tickets) 
      header "importing ticketmaster uk tickets"
        TicketmasterUKParser.new.crawl(@code,@fast_forward)
    end
    if (_import_ticketnetwork_tickets) 
      header "importing ticketnetwork tickets"
        TicketnetworkParser.new.crawl(@code,@fast_forward)
    end
    if (_import_ticketsnow_tickets) 
      header "importing ticketsnow tickets"
        TicketsnowParser.new.crawl(@code,@fast_forward)
    end
    if (_assign_match_probability) 
      header "starting assign match probability"
      assign_match_probability
    end
    if (_find_valid_urls) 
      header "finding_valid_urls"
      find_valid_urls
    end
    if (_find_metro_zips) 
      header "find_metro_zips"
      find_metro_zips
    end
    if (_geocode_venues) 
      header "geocoding venues"
      geocode_venues
    end
    if (_geocode_metros) 
      header "geocoding metros"
      geocode_metros
    end
    if (_put_venues_in_metros)
      header "putting venues in metros"
      put_venues_in_metros
    end
    if (_make_matches_from_imported_events) 
      header "making matches from imported events"
      make_matches_from_imported_events
    end
    if (_link_places_to_venues) 
      header "linking places to venues"
      link_places_to_venues
    end
    if (_search) 
      header "starting search"
      search
    end
    

#  rescue => e
#    handle_exception e
  end
end

def handle_exception (e)
begin
  ExceptionMailer.logger=@logger
  ExceptionMailer.template_root="../app/views"
  ExceptionMailer::deliver_snapshot("#{@metro_code} daemon",e) 
  puts e if e
  puts e.backtrace.join("\n") if e
rescue 
rescue Timeout::Error
end
end

#  ActiveRecord::Base.logger = Logger.new(STDOUT) if ENV['RAILS_ENV']!="production"


# program entry point
if (!ARGV.index("help").nil? or ARGV.empty?)
  puts "Tourfilter Import Events Daemon: imports events from ticketmaster, live nation, etc."
  puts <<-S
    Usage: ruby import_events_daemon.rb 
    [import_ticketmaster_us_venues_from_file]  
    [import_stubhub_tickets] [import_ticketmaster_tickets] [import_ticketnetwork_tickets] [import_ticketsnow_tickets]
    [find_metro_zips] [geocode_metros] 
    [geocode_venues] [put_venues_in_metros] [link_places_to_venues] 
    [search]  [assign_match_probability] [make_matches_from_imported_events]
    [mark_remaining_events_as_rejected]
    [debug] [fast-forward] 
    [place n] [file_name] [code n] [metro <code>] [term <term>] [source <source>] [country_code <2-letter country_code>]
    S
  puts "Author: chris marstall Dec. 2007 - Mar. 2008"
  exit
else
  puts "for usage: ruby import_events_daemon.rb help"
end
main(ARGV)
