class TourfilterBaseSweeper < ActionController::Caching::Sweeper  
  # expire_user_page - invalidate the l1-cache for this user ...
  def expire_user_page(user)
    puts "!?!?!?!?HERERERE!!!!!!!!!!!!???!?!?!?!"+user.name
    expire_page(:controller => "users", :action=> user.name)
    puts "HOLY SHIT!?!?!?!?HERERERE!!!!!!!!!!!!???!?!?!?!"+user.name
  end
  
  # expire_term_fragment - invalidate the l2 term fragment and all l1-user page caches that contain it.
  def expire_term_fragment(term) 
    #logger.info("FOO!!!!!!!!!!!!!")
    puts "HERERERE!!!!!!!!!!!!???!?!?!?!"+term.text
    expire_fragment(%r{/term/.+#{term.id}})
    term.users.each{|user|
      puts "HERERERE!!!!!!!!!!!!???!?!?!?!"+term.users.name
      expire_user_page(user)
      }
  end

  # expire_term_fragment_only - invalidate the l2 term fragment
  def expire_term_fragment_only(term) 
    expire_fragment(%r{/term/.+#{term.id}})
  end
end