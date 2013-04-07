class RecommendController < ApplicationController
  before_filter :must_be_known_user
  def recommend
    @match=Match.find(params[:id])
    if request.post?
      recommendation = Recommendation.new(params[:recommendation]) # also creates contact rows
      recommendation.match=@match
      logger.info("@youser.id: #{@youser.id}")
      recommendation.user_id=@youser.id
      recommendation.save!
      expire_recommendation_caches(recommendation)
      # now send out the notification email to the email contacts as well as internal recommendees
      RecommendationMailer.logger=logger
      begin
        email = RecommendationMailer::deliver_recommendation(self,recommendation)       
      rescue Exception
        logger.info $!
      end
      #redirect to homepage ...
      flash[:notice] = 
        "You have successfully recommended " +
        "<strong>#{@match.term.text}</strong> at <strong>#{@match.page.place.name}</strong>"
      redirect_to :controller => 'recommendations'
    else
      render :action => "recommend"
    end
  end

  def index 
    recommend
  end
end