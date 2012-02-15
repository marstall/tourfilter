class RssController < ApplicationController  

  #caches_page :index
  
  def about
    @full_width_footer=true    
  end
  
  def sms_tonight
    @matches= Match.matches_for_today_by_popularity
    render(:action=>"sms_tonight",:layout=>false)
  end

  def podcast
    @rss_title="tourfilter #{@metro.downcase} podcast"
    @tracks = Track.find_all_with_filename(@metro_code)
    logger.info(@tracks.size)
    render(:action=>"pcast", :layout=>false)
  end

  def podcast_link
    #2. Set Content-Type to "application/octet-stream"
    #3. If your file does not end in .pcast, be sure to set the Content-Disposition to "attachment; filename=whatever.pcast"
    headers["Content-Type"] = "application/octet-stream"
    render(:action=>"podcast_link",:layout=>false)
  end
  
  def rss
    @matches = nil
    user_name=params[:user_name]
    sort=params[:sort]
    @rss_title="tourfilter #{@metro.downcase} shows"
    if user_name
      begin
        @user = User.find_by_name(user_name)
        @rss_title="tourfilter #{@metro.downcase} shows for #{@user.name}"
        @matches = Match.current_for_user(@user,100)
        # also include current matches recommended by the user's recommenders
        some_recommended_matches=false
        @user.recommenders.each{|recommender|
          some_recommended_matches=true
          @matches+=recommender.current_recommended_matches
          }
      rescue
        render :inline => "unexpected error finding matches for user #{@user_name}! (#{$!})"
        return
      end
    elsif sort=='featured'
      @matches=Match.current_with_feature
      @rss_title="tourfilter #{@metro.downcase} editors' picks"
    else
      @matches=Match.current(100)
    end
#      return if not @matches or @matches.empty?
    if not sort or sort != "by_concert_date"
      @matches.sort! {|x,y| y.id<=>x.id} 
    end
    render(:action=>"rss", :layout=>false)
  end
  
  def index
    rss
  end
end