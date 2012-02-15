require 'rubygems'
require 'mechanize'

class ImportParser
  include FileUtils

  def header (s)
    line ="****************************************************************"
    puts line
    puts line
    puts "***************** "+s
    puts line
    puts line  
  end

  def add_imported_event(uid,datetime_string,venue,artist_name,url,source,level,cancelled='no')
    raise "must pass uid" if uid.nil? or uid.strip.empty?
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
    ie.source=source
    ie.level=level
    ie.save
    return ie,verb
  end


  def strip_tags(s,sub=" ")
    s= s.to_s
    return "" if s.nil?
    s.gsub!(/<([^>]+)>/,sub)
    return "" if s.nil?
    s.gsub!(/(#{sub})+/,sub)
    return "" if s.nil?
    s.gsub!(/#{sub}$/,"")
    return "" if s.nil?
    s.gsub!(/^#{sub}/,"")
    return "" if s.nil?
    return s
  end

# look in cache - if it finds it there, return it. else wait <delay> seconds and fetch it
  def fetch_url_cached(url,delay=0) # returns body + was_cached
    agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
    cache_timeout=24*60*60 # 12 hours
    digest = Digest::MD5.hexdigest(url)
    mkdir "/tmp/tourfilter" rescue 
    filename="/tmp/tourfilter/#{digest.to_s}"
    # return the cached version if it exists and it is less that <cache_timeout> seconds old
    puts url
    puts digest
    puts filename
    text = File.read(filename) if filename and File.exists?(filename) and Time.now-File.atime(filename)<cache_timeout
    if text
      refresh_url,refresh_time = get_refresh(Hpricot(text))
      if refresh_url 
        return fetch_url_cached(refresh_url,refresh_time) 
      else
        return text
      end
    end

#    atime = File.atime(filename)`
#    puts "file exists?: #{File.exists?(filename)}"
#    puts "atime: #{atime}"
#    puts "now: #{Time.now}"
#    puts "cache_timeout: 180"
#    puts "Time.now-atime: #{Time.now-atime}"
    sleep delay
    page = agent.get(url)
#    puts "creating filename for url #{url}: #{filename}"
    rm_rf(filename)  if filename and File.exists?(filename)
    puts filename
    file = File.new(filename,"w")
    file.write(page.body)
    file.close
    return page.body
  end
  
# <META http-equiv="refresh" content="4;url=http://www.ticketweb.com/t3/sale/SaleEventDetail?dispatch=loadSelectionData&amp;eventId=294638&amp;REFERRAL_ID=tmfeed" />
  def get_refresh(doc)
    refreshes = (doc/:meta)
    refresh = nil
    refreshes.each{|_refresh|
      he =_refresh.attributes['http-equiv']
      refresh = _refresh if he=='refresh'
    }
    if refresh.nil?
      return nil,nil
    end
    content = refresh.attributes['content'] 
    timeout = content.scan(/^\d+/).first.to_i rescue 0
    matches = content.scan(/\;url=(.+)/)
    url = matches[0][0] rescue nil
    return url,timeout
  end
  

 # look in cache - if it finds it there, return it. else wait <delay> seconds and fetch it
  def fetch_url(agent,url,delay=0) # returns body + was_cached
    cache_timeout=72*60*60 # 1/2 day
    digest = Digest::MD5.hexdigest(url)
    dir="/tmp/tourfilter/"
    mkdir dir rescue
    filename="#{dir}#{digest}"
#    puts filename
    # return the cached version if it exists and it is less that <cache_timeout> seconds old
    return File.read(filename),true if File.exists?(filename) and Time.now-File.atime(filename)<cache_timeout
#    atime = File.atime(filename)
#    puts "file exists?: #{File.exists?(filename)}"
#    puts "atime: #{atime}"
#    puts "now: #{Time.now}"
#    puts "cache_timeout: 180"
#    puts "Time.now-atime: #{Time.now-atime}"
    sleep delay
    page = agent.get(url)
#    puts "creating filename for url #{url}: #{filename}"
    rm_rf(filename)
    file = File.new(filename,"w")
    file.write(page.body)
    file.close
    return page.body,false
  end

  def initialize_crawl_agent
    agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
    agent.user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    agent
  end

  def create_search_url(start)
    start||="0"
#    google_url = "http://www.google.com/search?q=inurl:#{@url_specifier}&hl=en&client=safari&rls=en&start=[num]&sa=N&filter=0"
    yahoo_url="http://search.yahoo.com/search?p=inurl:#{@url_specifier}+domain:#{@domain}&n=100&ei=UTF-8&y=Search&vm=p&xargs=0&pstart=1&b=#{start+1}"
    altavista_url="http://www.altavista.com/web/results?itag=ody&kgs=1&kls=0&q=domain:#{@domain}+inurl:#{@url_specifier}+#{@phrase}&stq=#{start}"
  end

  def find_valid_urls 
    @count=0
    @last_as_concat=""
    # using google, find a list of valid urls - do this only once every few months
    puts "finding valid urls for url_specifier #{@url_specifier}"
    agent = WWW::Mechanize.new { |a| a.log = Logger.new("mech.log") }
    agent.user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    0.upto(100){|i|
        start=i*10
        search_url = create_search_url(start)
#       puts start
        puts "fetching #{search_url}"
        sleep 1  
#        next
        page = agent.get(search_url)
        break unless process_body page.body
      }
  end
  
  #http://rds.yahoo.com/_ylt=A0geu6F5A4BHs34BaTlXNyoA;_ylu=X3oDMTFiY2I0ODdqBHNlYwNzcgRwb3MDMTAyBGNvbG8DYWMyBHZ0aWQDWVMxOThfODIEbANXUzE-/SIG=11qcb7kn3/EXP=1199658233/**http%3a//www.ticketmaster.com/venue/112/  
  #http://rds.yahoo.com/_ylt=A0geu6F5A4BHs34BazlXNyoA;_ylu=X3oDMTFiYWhmY2htBHNlYwNzcgRwb3MDMTAzBGNvbG8DYWMyBHZ0aWQDWVMxOThfODIEbANXUzE-/SIG=11s3l541p/EXP=1199658233/**http%3a//www.ticketmaster.com/venue/237575
  def process_body body
    # loop through all <a> tags, save ones that have @url_specifier in them
    #    puts body
    doc = Hpricot(body)
    as =(doc/"a")
    at_least_one_link_found=false
    as_concat=""
    as.each{|a|
      href = a.attributes['href']
      #      puts href
      href.gsub! /^.+?\*\*/,""
      href.gsub! "%3a",":"
      next unless href.index(@url_specifier) and not href.index("cache")
      @count+=1
      puts "#{href} (#{@count})"
      as_concat="#{as_concat}_#{href}"
      at_least_one_link_found=true
      }
#    puts as_concat
#    puts @last_as_concat
    if as_concat==@last_as_concat
#      puts "repeat page"
      return false 
    end
    @last_as_concat=as_concat
    return at_least_one_link_found
  end

end