class BrowseController < ApplicationController  
  #caches_page :index
  
  def browse    
    # make a list of all matches, sorted by date
    @recent_matches = Match.find(:all,
               :order => "id desc",
               :limit => 100)
    @recent_users = User.find(:all,
                :order => "id desc",
                :limit => 100)
    
    render :action => "browse"
  end

  def index
    @full_width_footer=true     
    browse
  end
end