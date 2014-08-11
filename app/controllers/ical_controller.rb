require 'icalendar'

class IcalController < ApplicationController  

  def about
    @full_width_footer=true    
  end
  
  def ical
    headers["Content-Type"] = "text/calendar"
    user_name=params[:user_name]
    if user_name
      if prepare_ical_data
        render(:layout=>false,:inline=>@ical_data)
      end
    else
      render(:layout=>false,:action=>"ical")
    end
  end

  def prepare_ical_data
    calendar_name=""
    matches = nil
    user_name=params[:user_name]
    featured=false
    if user_name and user_name!='featured'
      begin
        user = User.find_by_name(user_name)
        calendar_name="tourfilter: #{user.name}'s #{@metro.downcase} concerts"
        matches = Match.matches_within_n_days_for_user(10000,0,user)                
        # also include current matches recommended by the user's recommenders
#        user.recommenders.each{|recommender|
#          matches+=recommender.current_recommended_matches
#          }
      rescue
        render :inline => "unexpected error finding matches for user #{user_name}! (#{$!})"
        return false
      end
    elsif user_name=='featured'
      featured=true
      matches=Match.current_with_feature
      calendar_name="tourfilter: #{@metro.downcase} editors' picks"
    else
      matches = Match.matches_within_n_days(365)
      calendar_name="tourfilter: #{@metro.downcase} concerts"
    end
    #return if not matches or matches.empty?
    
    cal = Icalendar::Calendar.new
    cal.custom_property("X-WR-CALNAME",calendar_name)
    
    total_time_in_loop=0.0
    matches.each{|match|
      begin
        @before=Time.now
        event = Icalendar::Event.new
        next if not match.date_for_sorting or not match.day # exclude events that don't have a full date associated with them
        event.timestamp=DateTime.now
        if match.imported_event_id
          event.start=match.date_for_sorting.to_datetime
          event.end=match.date_for_sorting.to_datetime
        else
          event.start=DateTime.new(match.year,match.month,match.day,20) 
          event.end=DateTime.new(match.year,match.month,match.day,20)
        end
        if featured
           event.summary="editors' pick: #{match.term.text}"
        else
          event.summary=match.match_term_text rescue match.term.text
        end
        event.location=match.match_page_place_name rescue match.page.place.name
        page = Page.new
        page.body=match.match_page_body rescue ""
        precis = ""# page.fast_precis(match.match_term_text,'<<<','>>>') rescue match.feature.description
        term = Term.new
        term.text=match.match_term_text rescue match.term.text
        url_text=term.url_text
        event.description="#{precis}"
        event.url="http://www.tourfilter.com/#{term.url_text}"
        event.uid=match.id
        # tickets
        #ticket_urls,price_low,price_high = match.ticket_urls
        #event.add_resource(ticket_urls.to_json.gsub(":","&#58;"))
        cal.add(event)
        delta=Time.now-@before
        total_time_in_loop+=delta
      rescue
      end
    }
    logger.info("ICAL total vevents for ical: #{matches.size}")
    logger.info("ICAL total time in loop: #{total_time_in_loop}")
    logger.info("ICAL average time per loop: #{total_time_in_loop/matches.size}")
    @matches=matches
    @ical_data = cal.to_ical
  end
  
  def index
    ical
  end
end