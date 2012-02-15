class XspfController < ApplicationController  

  #caches_page :index
  
  def about
    @full_width_footer=true    
  end
  

  def xspf
    # sorting methods:
    # by_date_added|by_concert_date|random|by_club_name|by_num_trackers
    #  - by date added (default)
    #  - by concert date
    #  - random/shuffle
    #  - by club
    #  - by popularity
    #  - by featured
    sort=params[:sort]
    id=params[:id].to_i rescue return
    if sort=="featured"
      matches = Match.current_with_feature
      @matches=Array.new
      # put the clicked-on artist first
      matches.each{|match|
        @matches<<match if match.feature.id==id
        }
      matches.each{|match|
        @matches<<match unless match.feature.id==id
        }
      render(:action=>"xspf_featured", :layout=>false)
    else
      @tracks = Track.find_all_with_filename(@metro_code,sort)
      render(:action=>"xspf", :layout=>false)
    end
  end
  
  def featured_playlist
    render(:action=>"featured_playlist", :layout=>false)
  end

  def xspf_popup
    render(:action=>"xspf_popup", :layout=>false)
  end

  def index
    xspf
  end
end