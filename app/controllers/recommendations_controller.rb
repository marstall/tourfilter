class RecommendationsController < ApplicationController
  def recommendations
    @full_width_footer=true
    @recommendations=Recommendation.current_with_text(200)
    render :action => "recommendations"
  end

  def index 
    recommendations
  end
  
  
end