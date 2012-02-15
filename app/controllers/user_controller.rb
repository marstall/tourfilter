class UserController < ApplicationController  
#  caches_page :index
  caches_page :badge
  #cache_sweeper :terms_users_sweeper
  #cache_sweeper :recommendees_recommenders_sweeper
  
  def albums
    @user=User.find_by_name(params[:id])      
    if !@youser_known
      render(:layout => false)
      return
    end
    terms=@user.terms
    ids=terms.collect{|term|term.id}.join(",")
    @items = Item.find_by_sql <<-SQL
      select * from items 
      where term_id in (#{ids})
      and medium_image_url is not null and length(medium_image_url)>0
      and artist is not null and length(artist)>0
      group by title
      order by artist asc,release_date desc
      SQL
  end

  def badge
    @badge=true
    index
    render(:inline=>"// unknown user!",:layout=>false) and return if not @user
    @num=Integer(params[:num]||10)
    @badge_matches=Array.new
    @matches.each_with_index{|match,i| 
        @badge_matches<<match if match.day
        break if @badge_matches.size>=@num
      } 
    @title=params[:title]||"upcoming #{@metro.downcase} shows"
    page = render_to_string(:action=>"badge",:layout=>false)
    page.gsub!(/[\n\r]/,"")
    page.gsub!(/[']/,"&#39;")
    page_with_js="document.write('#{page}');"
    render(:inline=>page_with_js,:layout=>false)
  end
  
  def show_badge
    page_with_js="<div style='max-width:180px;background-color:#EEF'><script language='javascript' " +
                " src='http://www.tourfilter.local/badge/#{params[:username]}'</script></div>"
    render(:inline=>page_with_js,:layout=>false)
  end
  
  def all_bands
    begin
      user=User.find_by_name(params[:username])
     rescue
      render("unknown")
    end
    render(:inline=>user.terms.collect{|term|term.text.downcase}.join(','))
  end

  def index
    @hide_login=true
    @cached=true
    begin
      @user=User.find_by_name(params[:username])
     rescue
      render(:action => :unknown)
    end
    @header_title="#{@user.name}"
    return if not @user
    @matches=@user.future_matches
    logger.info("#matches: #{@matches.size}")
    return if @badge
    setup_calendar(@user) 
#    @matched_terms.each{|term| matched_term_ids[term.id]=true}
    @unmatched_terms = Array.new
    #@unmatched terms is all_terms minus @matched_terms    
    @user.terms_alpha.each {|term| @unmatched_terms<<term if not @matched_term_ids[term.id]}

    @is_recommendee = false
    @is_recommendee = @user.is_recommendee(@youser) if @youser_known    
    render(:action => :unknown) if @user==nil 
  end
  
  def mini_register
    logger.info "mini_register"
    term_id = params[:term_id]
    begin
      logger.info "term_id is #{term_id}"
      @term = Term.find(term_id)
    rescue      
      logger.info "EXCEPTION"
      logger.info $!
    end
    #render(:layout => false)
  end

  def term_from_match
    match_id = params[:id]
    match = Match.find(match_id)
    return unless match
    @term=@tracked_term = match.term
    if !@youser_known
      mini_register
      render( :action => :mini_register, :layout =>false)
      return 
    end
    @youser.add_term(@tracked_term)
    expire_term_fragment(@tracked_term)
    render(:inline=>"You now track #{@tracked_term.text}!")
  end

  def term
    term_id = params[:id]
    term_text = params[:term_text]
    note = params[:note]
    note_entity = params[:note_entity]
    if term_id
      @tracked_term = Term.find(term_id)
    else
      @tracked_term = Term.find_by_text(term_text)
    end
    @youser.add_term(@tracked_term,note,note_entity)
    render(:inline => "<span style='vertical-align:1px'><img src='/images/check.png'></span>")
  end

  def term_
    term_id = params[:term_id]
    if !@youser_known
      mini_register
      render( :action => :mini_register, :layout =>false)
      return 
    end
#    @parent_user_id=params[:parent_user_id]
    @tracked_term = Term.find(term_id)
    #if !@youser.tracks_term @tracked_term
    @youser.add_term(@tracked_term)
    expire_term_fragment(@tracked_term)
    render(:layout => false)
  end
  
  def manage_recommendations
    user_id = params[:id]
    user_id = params[:user_id] if !user_id
    @user=User.find_by_id(user_id)      
    if !@youser_known
      render(:layout => false)
      return
    end
    d = params[:do]
    if d=="create"
      rr = 
        RecommendeesRecommenders.find_by_recommendee_id_and_recommender_id(@youser.id,user_id)
      if !rr
        rr=RecommendeesRecommenders.new
        rr.recommendee_id=@youser.id  
        rr.recommender_id=user_id
        rr.save
        Action.user_followed_user(@metro_code,@youser,@user)
#        expire_user_page(rr.recommendee)
#        expire_user_page(rr.recommender)
        begin
          NewRecommendeeMailer::deliver_new_recommendee(self,rr) unless ENV['RAILS_ENV']=='development'
        rescue Exception
          logger.info $!
        end
        @is_recommendee=true
      end
    end
    if d=="delete"
      rr = 
        RecommendeesRecommenders.find_by_recommendee_id_and_recommender_id(@youser.id,user_id)
      if !rr.nil? 
        RecommendeesRecommenders.delete_all(["id = ?",rr.id])
        Action.user_unfollowed_user(@metro_code,@youser,@user)
#        expire_user_page(rr.recommendee)
#        expire_user_page(rr.recommender)
      end
      @is_recommendee=false
    end
    @user=User.find_by_id(user_id)
    render(:layout => false)
  end
end
