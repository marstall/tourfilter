class AboutController < ApplicationController  
#  caches_page :index
    
  def about
    @full_width_footer=true    
    @feature1_sources=Source.find_featured("feature1")
    @feature2_sources=Source.find_featured("feature2")
    @feature3_sources=Source.find_featured("feature3")
    render :action => "about"
  end
  
  def index
    about
  end
  
  def logo
    render(:layout=>false)
  end
  
  def badge
    return if not must_be_known_user
    @full_width_footer=true    
  end
end