class CalendarController < ApplicationController  
#  caches_page :index
  
  def calendar2
    calendar
  end  
  
  def calendar
    @full_width_footer=true    
    render :action => "calendar"
  end

  def calendar_
    @full_width_footer=true    
    @days=Array.new
    @matches=Hash.new
    places = Place.find_all_active(@metro_code)
    _matches=Array.new
#    places.each{|place|
#      _matches+=place.matches_within_n_days(5)
#    }
    _matches=Match.matches_within_n_days(params[:days]||45)
    _matches.each{|match|
      if not @matches[match.date_for_sorting_date_only]
        @days<<match.date_for_sorting_date_only 
        @matches[match.date_for_sorting_date_only]=Array.new
      end
      @matches[match.date_for_sorting_date_only]<<match
    }
    render :action => "calendar"
  end
  
  def index
    calendar
  end
end
