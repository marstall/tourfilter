class RankingController < ApplicationController
  def popular_upcoming_matches
    @matches = Match.popular_upcoming_matches(30,10)
    
    render(:layout=>false)
  end
end