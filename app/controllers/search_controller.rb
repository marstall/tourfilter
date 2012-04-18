require "search.rb"
require 'json'
require 'open-uri'

class SearchController < ApplicationController
#  caches_page :homepage
  @total_shared_events=nil
  
  def total_shared_events
    @total_shared_events
  end
  
  def total_shared_events=(tse)
    @total_shared_events=tse
  end

  def search_auto_suggest
    @full_width_footer=true    
    render :action => "search_auto_suggest"
  end
  
  def index
    search
  end
  
  def log(name)
    begin
      value = instance_variable_get(name)
    rescue
      value="!canteval!"
    end
    logger.info("#{name} => #{value.to_s}")
  end

  def cache_total_shared_events
    return if total_shared_events
    @total_shared_events= SharedEvent.count_by_sql("select count(*) from shared_events")
  end
  
  def json
    
  end

  def badge
    @num=params[:num].to_i||10
    @show_club=params[:show_club]=="1"
    @hide_metro=params[:hide_metro]=="1"
    @hide_date=params[:hide_date]=="1"
    @max_width=params[:max_width]||"300"
    page = render_to_string(:action=>"badge",:layout=>false)
    page.gsub!(/[\n\r]/,"")
    page.gsub!(/[']/,"&#39;")
    page_with_js="document.write('#{page}');"
    render(:inline=>page_with_js,:layout=>false)
  end

  def ical
    cal = Icalendar::Calendar.new
    cal.custom_property("X-WR-CALNAME","#{@query.downcase}/tourfilter")
    @shared_events.each_with_index{|shared_event,i|
      cal.add(shared_event.to_ical_event(i))
    }
    @ical_data=cal.to_ical
    render(:action=>"ical",:layout=>false)
  end

  def fetch_url(url_text)
#    begin
      logger.info "url_text:#{url_text}" 
      user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      obj = open(url_text, "User-Agent" => user_agent)
      obj.read
#    rescue => e
#      "exception loading url '#{url_text}': #{$!}"
#    end
  end

  @@all_terms=nil

  def process_url_for_terms(url)
#    logger.info ("processing #{url}")
    body =fetch_url(url)
    logger.info("body #{body[0..100]}")
    return "" unless !body.strip.empty?
    unless @@all_terms
      @@all_terms=Hash.new
      SharedEvent.find(:all).each{|shared_event|
        @@all_terms[shared_event.summary.strip]=true
      }
    end
    logger.info("@@all_terms.size #{@@all_terms.size}")
    num_found=0
    all_found=Array.new
    body.scan(/[^,]+/).each{|token|
      logger.info token
      if @@all_terms[token.strip]
        all_found<<token 
        logger.info "found"
      end
    }
    all_found_string = all_found.join(",")
#    logger.info("ALL FOUND! #{all_found} !ALL FOUND")
    all_found_string
  end
  
  def homepage
    @hide_metro=true
    search
    render(:layout=>false)
  end

  def search
    @not_in_a_city=true
    @full_width_footer=true    
    @no_javascript=true
   if params[:query]
     @query=params[:query].sub(/\-concerts\-tickets$/,'')
     @query=@query.gsub(/[+-]/," ")
     @query=@query.gsub(/[+-]/," ")
    end
    if params[:signup]=~/next/i
      metro_name  = params[:object][:metro_code]  
      metro = Metro.find_by_name(metro_name)
      metro_code = metro.code rescue nil
      if metro_code.nil? or metro_code.strip.empty?
        flash[:error]="you must choose a metro!"
      else
        render(:inline=>"<script>location.href='/#{metro_code.downcase}/#{@query}';</script>",:layout=>false)
        return
      end
    end
#    if params[:search]=='search'
#      urlized_query=@query.gsub(' ','-')
#      render(:inline=>"<script>location.href='/search/#{urlized_query}';</script>",:layout=>false)
#      return
#    end
    return if @query.nil?
    if params[:url]
      @query=process_url_for_terms(params[:url]) 
    end
#    logger.info("QUERY! #{@query} !QUERY")
    @query.gsub(/(\_|\+)/,' ').strip
    @shared_event_hash=Hash.new
    @shared_event_hash[:summary]=@query
    @format = params[:format]||"html"
    if @format=="rss"
      @shared_events = SharedEvent.search(@shared_event_hash,10000)
      render(:action=>"rss",:layout=>false)
      return
    elsif @format=="json"
      @shared_events = SharedEvent.search(@shared_event_hash,10000)
      render(:action=>"json",:layout=>false)
      return
    elsif @format=="ical"
      @shared_events = SharedEvent.search(@shared_event_hash,10000)
      ical
      return
    elsif @format=="badge"
      @shared_events = SharedEvent.search(@shared_event_hash,10000)
      badge
      return
    end
    cache_total_shared_events
    @shared_events = SharedEvent.search(@shared_event_hash,200)
    render :action => "search"
  end
  
  def search_results
    cache_total_shared_events
    @shared_event_hash=Hash.new
    @term=@shared_event_hash[:summary]=CGI::unescape(request.raw_post)
    @shared_events = SharedEvent.search(@shared_event_hash)
    render :action => "search_results",:layout=>false 
  end
  
  def auto_complete_for_shared_event_summary
    term = params[:shared_event][:summary]
    @shared_events = SharedEvent.search(params[:shared_event])
    render :partial => "suggest" 
  end

end
