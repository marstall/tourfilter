require 'uri'
class TrackController < ApplicationController

  def track
    @hide_metro=true
    @full_width_footer = true
    #id = params[:id].gsub(/([A-Z])/,' \1').strip! 
    #use request_uri instead of params[:id] so that question marks aren't stripped out
    id = request.request_uri.sub(/\/track\//,'') 
    id =URI.decode(id).strip
    id = id.gsub(/(\_|\+)/,' ').strip.capitalize
    logger.info("band name: #{id}")
    @term=Term.find_by_text(id)
    @unknown=false
    if not @term
      @term=Term.new
      @term.text=id
      @unknown=true
    end
#    @hype_tracks=Track.find_by_term(@term,'mp3','hype',7)

#    get the tracks, too
#    @wfmu_tracks = Track.unique_by_term_text(id,'ram')
#    if not @wfmu_tracks or @wfmu_tracks.empty?
#    @double_wide_right_column=false 
#    @full_width_footer = true
#    end
    render :action => "track"
  end

  def index 
    track
  end

end
