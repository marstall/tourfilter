class DataController < ApplicationController

  def unescape_url(url)
    url = url.gsub(/__/,"/")
    url = url.gsub(/\|\|/,"?")
    url = url.gsub(/\~\~/,"&")
  end
  
  def track_click
    # do nothing, the url will get logged in page_views by the before-filter
    url = params[:url]
    referer = params[:referer]
    return if not url
    url = unescape_url(url)
    if referer
      referer = unescape_url(referer)
    end
    log_page_view(url,referer,"js")
    render(:inline => "tracked: #{params[:url]}")
  end

  def track_external_click
    # do nothing, the url will get logged in page_views by the before-filter
    ec = ExternalClick.new(params[:ec])
    if ec.url
      log_external_click(ec)
      render(:inline => "tracked:<br><br> params:#{params[:ec].inspect} <br><br>object: #{ec.inspect}")
    else
      render(:inline => "error: url blank")
    end
  end
  
  def recommended_matches
    user_id=Integer(params[:user_id])
    if user_id
      begin 
        user = User.find(user_id)
        @matches = user.current_recommended_matches
      rescue
      end
    end
    render(:layout => false)
  end



  # returns a comma-delimited list of the terms youser shares with user_id.
  def does_user_track_term
    @result="no"
    term_id=Integer(params[:id])
    if @youser_known && term_id
      @result="yes" if TermsUsers.find_by_term_id_and_user_id(term_id,@youser.id)
    end
    render(:inline=>@result,:layout => false)
  end


  def shared_matches_with_place
    place_id=Integer(params[:id])
    if @youser_known && place_id
      sql =  " select matches.id from terms_users,places,pages,matches "
      sql += " where terms_users.user_id=? and places.id=? "
      sql += " and terms_users.term_id=matches.term_id "
      sql += " and matches.status='notified' and matches.time_status='future' "
      sql += " and matches.page_id=pages.id and pages.place_id=places.id "
      matches = Match.find_by_sql([sql,@youser.id,place_id])
    end
    matches||=[]
    render(:inline=>matches.collect{|match|match.id}.join(','))
  end
  
  def shared_matches_with_user
    user_id=Integer(params[:id])
    if @youser_known && user_id
      sql =  " select terms.* from terms,terms_users tu1,terms_users tu2 "
      sql += " where tu1.term_id=terms.id and tu2.term_id=terms.id "
      sql += " and tu1.user_id=#{user_id} and tu2.user_id=#{@youser.id}"
      terms = Term.find_by_sql(sql)
        logger.info("terms.size: #{terms.size}")
      match_ids=Array.new
      terms.each{|term|
        logger.info("term")
        term.future_matches.each{|match|match_ids<<match.id}
      }
    end
    match_ids||=[]
    render(:inline=>match_ids.join(','))
  end  

  # returns a comma-delimited list of the terms youser shares with user_id.
  def shared_terms
    user_id=Integer(params[:user_id])
    if @youser_known && user_id
      sql =  " select terms.* from terms,terms_users tu1,terms_users tu2 "
      sql += " where tu1.term_id=terms.id and tu2.term_id=terms.id "
      sql += " and tu1.user_id=#{user_id} and tu2.user_id=#{@youser.id}"
      @_shared_terms = Term.find_by_sql(sql)
    end
    render(:layout => false)
  end

  # returns "true" if the youser gets recommendations from user_id. else, returns a blank page.
  def is_youser_recommendee 
    user_id=Integer(params[:user_id])
    if @youser_known && user_id
      if @youser.is_recommender(user_id)       
        render :text => "true" 
        return
      end
    end
    render :nothing => true
    #render(:layout => false)
  end
  
  def expire_match_caches
    result="error"
    match_id=params[:match_id]
    begin
      match = Match.find(match_id)
    rescue
    end
    if match
      expire_term_fragment(match.term)
      result="success"
    end
    render(:inline =>result)
  end

  def expire_term_caches
    term_id=params[:term_id]
    term_id=term_id.gsub(/[_-]/," ").strip
    result="error #{term_id}"
    logger.info "term_id: #{term_id}"
    begin
      term = Term.find(term_id)
    rescue
    end
    term = Term.find_by_text(term_id) if not term
    if term
      expire_term_fragment(term)
      result="success"
    end
    render(:inline =>result)
  end  
  
  # invalidates all l1- and l2- caches for any given term.
  def finalize_match_processing
    @log="Invalidating caches for matches in 'processing' state ...\n\n"
    @num_new_matches=0
    matches = Match.find_all_by_time_status("processing")
    matches.each{ |match|
      @num_new_matches+=1
      begin
        @log+="processing match #{match.id}: #{match.term.text} at #{match.page.place.name} ...\n"
        expire_term_fragment(match.term)
        @log+="Fragment and page caches expired for #{match.term.text}...\n\n"
        match.time_status="past"
        match.save
        @log+="Match saved with time_status='past'.\n\n"
      rescue
        @log+="Error processing a match\n\n"
      end
      } if matches
      render(:layout => false)
  end

  # invalidates all l1- and l2- caches for any given term.
  def invalidate_caches_for_new_matches
    @log="Invalidating caches for new matches ...\n\n"
    @num_new_matches=0
    new_matches = Match.find_all_by_status("new")
    new_matches.each{ |match|
      @num_new_matches+=1
      begin
        @log+="New match #{match.id}: #{match.term.text} at #{match.page.place.name} ...\n"
        expire_term_fragment(match.term)
        @log+="Fragment and page caches expired for #{match.term.text}...\n\n"
      rescue
        @log+="Error processing a match\n\n"
      end
      } if new_matches
      render(:layout => false)
  end
end

