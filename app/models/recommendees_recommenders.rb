class RecommendeesRecommenders < ActiveRecord::Base

  def recommender
    User.find(recommender_id)
  end        

  def recommendee
    User.find(recommendee_id)
  end        
end
