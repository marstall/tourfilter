require 'json'

class BandsController < ApplicationController
#  caches_page :index
#  caches_page :bands

#  def self.cache_page(content, path,metro_code)
#    return unless perform_caching
#    path.sub!("/#{metro_code}","")
#    path="/#{metro_code}/bands/#{path}" 
#    benchmark "Cached page: #{page_cache_file(path)}" do
#      FileUtils.makedirs(File.dirname(page_cache_path(path)))
#      File.open(page_cache_path(path), "wb+") { |f| f.write(content) }
#    end
#  end
  
#  def cache_page(content = nil, options = nil)
#  return unless perform_caching && caching_allowed

 # path = case options
#    when Hash
#      url_for(options.merge(:only_path => true, :skip_relative_url_root => true, :format => params[:format]))
#    when String
#      options
#    else
#      request.path
#  end

#  self.class.cache_page(content || response.body, path,@metro_code)
#end


#  after_filter :cache_page, :only=>:bands
  before_filter :prepare_external_click_hash
  
  def prepare_external_click_hash
    super
    @external_click_hash['link_source']='web'
    @external_click_hash['page_type']='band'
  end
  
  def ticket_tester
    id = request.request_uri
    logger.info "+++ id #{id}"
    id.gsub!(/^\/\w+/,'')
    id.gsub!(/^\/bands\/ticket_tester/,"")
    id.gsub!(/^\/admin/,"")
    id.gsub!(/^\/more/,"")
    id.sub!(/\//,'') 
    id = id.gsub(/(\-|\_|%20)/,' ').strip
    @term=Term.find_by_text(id)
#    render(:partial=>'shared/tickets_old',:locals=>{:match=>@term.future_matches.last})
  end

  def figure_out_term
    #id = params[:id].gsub(/([A-Z])/,' \1').strip
    #use request_uri instead of params[:id] so that question marks aren't stripped out
    id = request.request_uri
    id.gsub!(/^\/\w+/,'')
    id.gsub!(/^\/bands/,"")
    id.gsub!(/^\/trackers/,"")
    id.gsub!(/^\/admin/,"")
    id.gsub!(/^\/more/,"")
    id.sub!(/\//,'') 
    @term=Term.find_by_text(id)
    if not @term
      id = id.gsub(/(\-|\_|%20)/,' ').strip
      @term=Term.find_by_text(id)
    end
    @unknown=false
    if not @term
      @term=Term.new
      @term.text=id
      @unknown=true
    end
    
  end

  def prepare_band_data(minimal=false)
    start_timer
    @double_wide_right_column = false
    @full_width_footer = true
    figure_out_term
    @term_text=@term.text
    @external_click_hash['page_name']=@term_text
#    @hype_tracks=Track.find_by_term(@term,'mp3','hype',7) unless minimal
    
    # get the tracks, too
#    @wfmu_tracks = Track.unique_by_term_text(id,'ram') unless minimal
#    if not @wfmu_tracks or @wfmu_tracks.empty?
#      @double_wide_right_column=false 
#      @full_width_footer = true
#    end
#    @secondary_tickets=SecondaryTicket.find_tickets(id)
    future_matches = @term.future_matches
    if future_matches
      _future_matches = Array.new
      one_with_date=false
      future_matches.each{|match|
        one_with_date=true if match.day
      }
      date_has_source = Hash.new
      future_matches.each{|match|
        date_slug = "#{match.month}-#{match.day}"
        date_has_source[date_slug]=true if match.source
      }
      @future_matches=Array.new
      future_matches.each{|match|
        date_slug = "#{match.month}-#{match.day}"
        next if one_with_date and not match.day
        next if not match.source and date_has_source[date_slug]
        @future_matches<<match
      }
      log_match_for_referer(@future_matches.first)
    end
    # user tickets
#    @utos = Array.new
#    @future_matches.each{|match|
#      @utos += match.user_ticket_offers
#    } if @future_matches

  	# title
#  	if @future_matches and not future_matches.empty?
#  		@page_title="#{@term.text.downcase} in #{@metro.downcase}: at #{future_matches.first.page.place.name.downcase} "
#  	else
  		@page_title = "#{@term_text.downcase} concerts in #{@metro.downcase}"
#  	end
 #   @append_minimal_title=true
    
    # nearby shows
#    hash=Hash.new
#    hash[:summary]=@term_text
#    hash[:metro_codes]= .nearby_metros.collect{|metro|metro.code}.reject{|i|@metro_code}
    metro = Metro.find_by_code(@metro_code)
#    @shared_events_ = SharedEvent.search_nearby(@term_text,metro.lat,metro.lng,400,5)
#    @shared_events = @shared_events_.reject{|shared_event|shared_event.metro_code==@metro_code}
  log_interval("prepare_band_data")
  end

  def trackers
    figure_out_term
  end


  def bands
    @show_imports=false
    @hide_login=true
    @show_ads=false
    @show_popup =true if not @youser and cookies[:no_band_page_upsell]!="true"
    prepare_band_data
    @header_title=@term.text
    render :action => "bands"
    cookies[:no_band_page_upsell] = {
                          :value => "true",
                          :expires => 10.years.from_now,
                          :domain => ".tourfilter.com",
                          :path => "/"
                      } 
    cookies[:no_band_page_upsell] = {
                          :value => "true",
                          :expires => 10.years.from_now,
                          :domain => ".tourfilter.local",
                          :path => "/"
                      } 
  end
  
  def more
      prepare_band_data
      render :action => "bands"
  end
  
  def admin
    prepare_band_data
    render :action => "admin"
  end

  def mini_register
    @term_text=params[:term_text]
    render(:layout=>false)
  end

  def show_comments
    use_full_width_footer
    @match=Match.find(params[:id])
  end

  def delete_comment
    comment_id=params[:id]
    logger.info("comment_id: #{comment_id}")
    comment=Comment.new
    error=false
    begin
      comment=Comment.find_by_id(Integer(comment_id))
    rescue
    end
    unless comment and comment.id
      flash[:error]="invalid comment id!"
      redirect_to(request.env["HTTP_REFERER"]||"/")
      return
    end

    if comment.user.id!=@youser.id
      flash[:error]="You can only delete your own comments!"
      redirect_to(request.env["HTTP_REFERER"]||"/")
      return
    end
    Comment.delete_all(["id=?",comment.id])
    invalidate_caches_for_match_comments(comment)
    flash[:notice]="Your comment was deleted!"
    redirect_to(request.env["HTTP_REFERER"]||"/")
  end

  def handler
    if not @youser.normal?
      render(:inline=>"You must set a username to comment! (go to <a href='/#{@metro_code}/settings'>settings</a>)")
      return
    end
    return if not @youser
    comment=Comment.new(params[:comment])
    comment.user_id=@youser.id
    comment.save
    if comment.errors.size>0
      render(:inline=>comment.render_errors.gsub('_',' '))
      return
    end
    # invalidate cache
    invalidate_caches_for_match_comments(comment)
    render :inline=>"comment created!",:layout=> false
  end

  def index 
    bands
  end
end