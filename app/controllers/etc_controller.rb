class EtcController < ApplicationController  
  #caches_page :index
    
  def etc
    @full_width_footer=true    
    render :action => "etc"
  end
  
  def index
    etc
  end
  
  def handler
    info = params[:info]
    if not info or info.empty?
      render(:inline => "You must enter something!")
      return 
    end
    render(:inline => "Thanks! You have successfully submitted information about your show. Our staff will take a look at it and if everything is OK we'll publish it within 24 hours. If it doesn't show up, email us at tourfilter@psychoastonomy.org.") 
    ListingRequestMailer::deliver_listing_request(info)
  end
end