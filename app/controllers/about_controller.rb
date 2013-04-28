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

  def notify
    puts "+++ notify"
    @request=request
    if request.post?
      if !params[:email_address]
        puts "+++ error notify"
        flash[:error]="You must enter an email address"
      else
        puts "+++ eror ok"
        beta = Beta.new
        beta.email_address=params[:email_address]
        flash[:notice]="Thanks! You're on the list."
      end
    else
      puts "+++ not a post. request.post? is #{request.post?}"
    end
  end
  
  def badge
    return if not must_be_known_user
    @full_width_footer=true    
  end
end
=begin
CREATE TABLE `betas` (
  `id` int(11) NOT NULL AUTO_INCREMENT,
  `email_address` varchar(255) DEFAULT NULL,
  `user_id` int(11) DEFAULT NULL,
  PRIMARY KEY (`id`)
)
=end