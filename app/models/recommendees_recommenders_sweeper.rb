class RecommendeesRecommendersSweeper < ActionController::Caching::Sweeper  
  observe RecommendeesRecommenders
  
  def invalidate_rr_caches(rr)
    # l1-expire the pages of the recommender and recommendee
#    expire_page(:controller => "users", :action=> rr.recommendee.name)
#    expire_page(:controller => "users", :action=> rr.recommender.name)
  end

  def before_destroy(rr)
#    logger.info "RecommendeesRecommendersSweeper.before_destroy"
#    invalidate_rr_caches(rr) 
  end
  
  def after_create(rr)
#    logger.info "RecommendeesRecommendersSweeper.after_create"
#    invalidate_rr_caches(rr)
  end
end