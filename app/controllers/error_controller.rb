class ErrorController < ApplicationController  
#  caches_page :index
    
  def error
    @full_width_footer=true    
    render :action => "error"
  end
  
  def index
    error
  end
end