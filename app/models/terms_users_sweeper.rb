class TermsUsersSweeper < ActionController::Caching::Sweeper  
  observe TermsUsers
  
  # expire_user_page - invalidate the l1-cache for this user ...
  def expire_user_page(user)
#    expire_page(:controller => "users", :action=> user.name)
  end
  
  # expire_term_fragment - invalidate the l2 term fragment and all l1-user page caches that contain it.
  def expire_term_fragment(term) 
#    expire_fragment(%r{/term/.+#{term.id}})
#    term.users.each{|user|
#      expire_user_page(user)
#      }
  end

  # expire_term_fragment_only - invalidate the l2 term fragment
  def expire_term_fragment_only(term) 
#    expire_fragment(%r{/term/.+#{term.id}})
  end

  def after_destroy(terms_users)
#    logger.info "TermsUsersSweeper.before_destroy"
#    term= Term.find(terms_users.term_id)
#    expire_term_fragment(term)
  end
  
  def after_create(terms_users)
    # cycle through all the users of the term and invalidate their fragment caches and user pages
#    logger.info "TermsUsersSweeper.after_create"
#    term= Term.find(terms_users.term_id)
#    expire_term_fragment(term)
  end
end 