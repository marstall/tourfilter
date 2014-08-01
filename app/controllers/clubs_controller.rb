class ClubsController < ApplicationController
  
  def clubs
    begin
      @hide_login=true
      @full_width_footer=true
      logger.info params.inspect
      id = params[:id]
      id = id.gsub(/\%26/,'&')
      id = id.gsub(/\%27/,'\'')
      id = id.gsub(/(\_|-|%20)/,' ').strip
      puts "id: #{id}"
      @place=Place.find_by_name(id)
      if @place.nil?
        # check to see if this is an external venue
        venue = Venue.find_by_name(id)
        if venue
          @place=Place.new
          @place.venue_id=venue.id
          @place.name=venue.name
        end
      end
      puts @place.name if @place
      @unknown=false
      if not @place
        @place=Place.new
        @place.name=id
        @unknown=true
      end
      @header_title=@place.name
      @place_url_name=@place.url_name rescue ""
      @featured_matches=@place.current_with_feature if @place and not @unknown
    end
      @days,@matches=setup_calendar(nil,@place,365)
      if params[:partial]
        render(:partial =>"shared/calendar",:locals=>{:direct_club_link=>true,:page=>'clubs'})
      else
        render :action => "clubs"
      end
  end

  def index 
    clubs
  end
  
  def club_listings
  end
end

=begin
      @days=Array.new
      @matches=Hash.new
      day_terms=Hash.new
      @place.current_matches.each{|match|
        match.date_for_sorting = match.date_for_sorting.to_date
        term_text=Term.normalize_text(match.term.text) rescue ""
        next if day_terms["#{match.date_for_sorting}:#{term_text.downcase}"]
        day_terms["#{match.date_for_sorting}:#{term_text.downcase}"]=true
        if not @matches[match.date_for_sorting]
          @days<<match.date_for_sorting 
          @matches[match.date_for_sorting]=Array.new
        end
        @matches[match.date_for_sorting]<<match
      }
    end
=end
