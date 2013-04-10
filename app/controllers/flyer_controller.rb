class FlyerController < ApplicationController
  
  include QuickAuthModule
  before_filter :must_be_admin, :only=>:admin_handler
  
  def calculate_tags_array(show_hashtags=true)
    tags_array = [""]
    tags_array += Tag.SUPERTAGS
    Tag.popular(20).each{|tag|
      tags_array<<"##{tag.text} (#{tag.cnt})"
    } if show_hashtags
    return tags_array
  end
  
  def flyer
    @imported_event = ImportedEvent.find(params[:id]) 
    render(:inline=>"unrecognized id") and return unless @imported_event
    @page_title = @imported_event.body
    @hide_login=true
    render(:layout=>'minimal_layout',:action=>'flyer')
  end

  def post_flyer
    @tags_array = calculate_tags_array(false)
    
    return if not must_be_known_user("You've successfully uploaded your flyer, but you must create an account to post it!")
    @image_url = params[:url]
    id = params[:id]
    if id
      @imported_event = ImportedEvent.find(id)
      if (@imported_event.user_id!=@youser.id) && (!@youser.is_admin)
        render(:inline=>"You do not have permission to edit this flyer.")
        return
      else
        @image_url = @imported_event.image_url
      end
    else
      if not @image_url
        render :inline=>'no image uploaded'
      end
    end
  end
  
  def promote
    @imported_event = ImportedEvent.find(params[:id])
  end

  def reflyer
    if not quick_authenticate_with_user(@youser,params)
      flash[:error]="To reflyer this, first create an account!"
      render(:js=>"document.location.href='/#{@metro_code}/basic_signup?redirect_url=#{request.referer}'")
      return
    end
#    ImportedEventEditedMailer::deliver_imported_event_edited(event, metro_code, @youser, action)
    imported_event_id = params[:id]
    imported_event = ImportedEvent.find(imported_event_id)
    ieu = ImportedEventsUser.find_by_user_id_and_imported_event_id(@youser.id,imported_event_id)
    ieu ||= ImportedEventsUser.new
    ieu.imported_event_id=imported_event_id
    ieu.user_id = @youser.id
    ieu.metro_code=@metro_code
    ieu.deleted_flag = false
    ieu.save
    Action.user_reflyered(metro_code,@youser,imported_event)
#    render(:inline=>'reflyered!')
#    render(:js=>"document.writeln(\"<button id='#{imported_event_id}' style='font-size:24px;' class='btn btn-primary unflyer_button' data-name='simple get'>+ unflyer</button>\");prep_huds()")
  render(:inline=>"reflyered")
  
  end

  def unflyer
    if not quick_authenticate_with_user(@youser,params)
      render(:inline=>"you must have an account to reflyer. <a href='/#{@metro_code}/basic_signup?redirect_url=#{request.referer}'>sign up for one!</a>")
      return
    end
#    ImportedEventEditedMailer::deliver_imported_event_edited(event, metro_code, @youser, action)
    imported_event_id = params[:id]
    imported_event = ImportedEvent.find(imported_event_id)
    ieu = ImportedEventsUser.find_by_user_id_and_imported_event_id(@youser.id,imported_event_id)
    ieu.deleted_flag=true
    ieu.save
    Action.user_unflyered(metro_code,@youser,imported_event)
#    render(:js=>"jQuery('##{imported_event_id}').removeClass('reflyer_button').addClass('unflyer_button').html('+ reflyer');prep_huds()")
    render(:inline=>"unflyered")
#    render(:js=>"document.writeln(\"<button id='#{imported_event_id}' style='font-size:24px;' class='btn btn-primary reflyer_button' data-name='simple get'>+ reflyer</button>\");prep_huds()")
  end

  def auto_complete_for_imported_event_venue_name
    @places = Place.find_in_metro_like_name(@metro_code,params[:imported_event][:venue_name])
    render :inline => '<%= content_tag(:ul, @places.map { |place| content_tag(:li, h("#{place.name}")) }) %>'
  end

  def tag
    flyers
  end

  def flyers
    @tags=params[:tags] 
    @start = params[:start]
    @num = params[:num]
    @query = params["tag"]["text"] if params["tag"] 
    @query= nil if @query and @query.strip.size==0
    @tags=nil if @tags=='all'
    @header_title=@tags
    @header_title="##@header_title" unless Tag.is_supertag(@tags) or @tags.nil? or @tags.empty?

    @order=params[:order] || get_cookie(:order)
#    @order = "random" #if not @order
    set_cookie(:order,@order)
    order_hash=
    {
      "created"=>"created_at desc",
      "popular"=>"created_at desc",
      "date"=>"date desc",
      "random"=>"rand()"
    }
    _order = order_hash[@order]
    
    metro_code=params[:mc]||@metro_code
    metro_code=nil if metro_code=='all'
    
    options = {
              :show_flagged=>params[:show_flagged]
              }
    params = {
              :metro_code=>metro_code,
              :order=>_order,
              :tags=>@tags,
              :query=>@query,
              :start=>@start,
              :num=>@num
             }


    @imported_events = ImportedEvent.all_flyers(params,options)
    render(:action=>'flyers')
  end
  
  def flyer_validate(event)
    @errors=Array.new
    date=nil
    @errors<<"please choose an event type" if event.category==''
    @errors<<"please enter a date in the future" if event.date<DateTime.now
    @errors<<"please enter an end date on or later than the start date" if event.multiple_days and event.end_date<event.date
    @errors<<"must upload an image" unless event.image_url and event.image_url=~/^http/
    @errors<<"post as user not found." if (@youser.is_admin and (not event.post_as or not event.post_as.empty?)) and not User.find_by_name(event.post_as) 
#    @errors<<"invalid character" if event.venue_name+event.body+event.description+event.url=~HTML_REGEXP
#    @errors<<"must select a metro" unless params[:object][:metro_code] and params[:object][:metro_code].strip.size>3
    return @errors.empty?
  end

  def flyer_handler
    if params[:submit]=='cancel'
      render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
      return
    end
    event=nil
    action=" posted a flyer "
    if params[:id]
      action=" edited a flyer "
      event = ImportedEvent.find(params[:id])
    else
      event = ImportedEvent.new
    end
    original_image_url=event.image_url
    event.update_attributes(params[:imported_event])
    event.flagged=nil if event.flagged and event.flagged.strip.size==0
    
    event.source='user'
    event.level='primary'
    event.status='new'
    event.venue_id = -1 # yes, it's a hack ..
    if @youser
      u = @youser
      u = User.find_by_name(event.post_as) if event.post_as and not event.post_as.empty? and @youser.is_admin
      event.user_id=u.id
      event.username=u.name
    end
    event.user_metro=event.metro_code=@metro_code
#    venue = find_or_create_venue(event.venue_name,params[:imported_event][:address])
#    event.venue_name=venue.name
#    event.venue_id=venue.id
#    dupe =event.find_dupe
#    if dupe and not dupe.empty?
#      @errors<<"duplicate event!"
#      render(:layout=>false)
#      return
#    end
    if original_image_url!=event.image_url
      duplicate_image = event.process_image 
      if duplicate_image
        @errors=Array.new
        @errors<<"This flyer is too similar to an <a href='#{duplicate_image.imported_event.oneup_url(@metro_code)}'>existing flyer</a>."
        render(:layout=>false)
        return
      end
    end
    unless flyer_validate(event)
      render(:layout=>false)
      return
    end

    event.do_term_search_process
    event.do_hashtag_process
    event.save
    Action.user_added_flyer(metro_code,@youser,event)
    
    if @youser
      ieu = ImportedEventsUser.new
      ieu.user_id = @youser.id
      ieu.imported_event_id = event.id
      ieu.metro_code = @metro_code
      ieu.save
    end
    
    ImportedEventEditedMailer::deliver_imported_event_edited(event, metro_code, @youser, action)
    
  # if direct_admin_submit
  #    handle_direct_submit(event) 
  #    term_url=url("/#{event.body}")
  #    render(:inline=>"Show submitted. It will appear on the site within 24 hrs, once caches have cleared. You should be able to see it here: <a href='#{term_url}'>#{event.body}</a>",:layout=>false)
  #  else
  flash[:notice]="flyer successfully posted to tourfilter!"# " Here are some other ways to promote your show."
  render(:inline=>"<script>location.href='/#{@metro_code}';</script>")#"/promote/#{event.id}';</script>",:layout=>false)
  #  end
  end


  def admin_handler
    id = params[:imported_event_id]
    at_ids = params[:artist_term]
#    puts "+++ at_ids: #{at_ids.size}" if at_ids
    ie = ImportedEvent.find(id)
    ie.flagged=params[:flagged]
    params.each_key{|param|
#      puts "#{param} : #{params[param]}"
      }

    button_pressed = params[:"button_value_#{id}"]
    if button_pressed=='flag' && (params[:flagged].strip.empty?)
      render(:inline=> "<span style='color:red'>you must enter a reason for the flag.</span>")
      return
    end
    if button_pressed=='flag'
      puts "+++ saving ie #{ie.id} with flagged value of #{ie.flagged}"
      ie.save
      ImportedEventEditedMailer::deliver_imported_event_edited(ie, metro_code, @youser, "flagged flyer" )
      ImportedEventFlaggedMailer::deliver_imported_event_flagged(ie, metro_code, @youser, params[:flagged] )
      render(:inline=> "<script>jQuery('#ie_#{ie.id}').hide();alert('flyer #{ie.id} successfully flagged.')</script>")
      return
    else
      # user clicked "confirm & send" instead
      if ie.flagged
#        ImportedEventUnflaggedMailer::deliver_imported_event_unflagged(ie, metro_code, @youser)
      end
      
      ie.flagged=nil
      ie.status='made_match'
      ie.body = params[:body]
      artist_terms = ie.artist_terms
      good = ""
      bad = ""
      valid_artist_terms = []
      invalid_artist_terms = []
      artist_terms.each{|at|
        if params[:"artist_term_#{at.id}"]=="1"
          at.status='valid'
          valid_artist_terms<<at 
          good+=at.term_text+","
        else
          at.status='invalid'
          invalid_artist_terms<<at 
          bad+=at.term_text+","
        end
        at.save
      }
      ie.tags.each{|tag| tag.delete}
      tags = ie.do_hashtag_process
      ie.save
      if tags.empty?
        tag_string=""
      else
        tag_string="found tags " + tags.collect {|tag|tag.text}.join(",")
      end
      Action.admin_approved_flyer(metro_code,@youser,ie,"posted by #{ie.user.name}: '#{ie.body}' ","[BAD: #{bad}] [GOOD: #{good}]")
      script="<script>jQuery(\"#ie_#{id}\").removeClass('unprocessed_flyer')</script>"
      render(:inline=> "<span style='color:green'>success! #{tag_string}. approved shows #{good}</span>#{script}")
        
    end
  end
  
  def find_or_create_venue(name,address=nil)
    venue = Venue.find_by_name_and_state(name,Metro.find_by_code(@metro_code).state)
    if not venue
      venue = Venue.new
      venue.name=name
      venue.address=address
      venue.source='user'
      venue.user_id=@youser.id
      venue.username=@youser.name
      venue.user_metro=@metro_code
      venue.save
      mv = MetrosVenue.new  
      mv.metro_code=@metro_code#params[:object][:metro_code]
      mv.venue_id=venue.id
      mv.save
    end
    return venue
  end
  
  def delete
    id = params[:id]
    begin
      @imported_event=ImportedEvent.find(id)
    rescue
    end
    if not @imported_event
      render(:inline=>'unkown id')
      return
    end
    if (@youser.is_admin or @imported_event.is_owner(@youser,@metro_code))
      ImportedEventEditedMailer::deliver_imported_event_edited(@imported_event, metro_code, @youser, "deleted flyer" )
      ImportedEvent.find(id).destroy
      flash[:notice]="flyer successfully deleted."
      redirect_to("/flyers")
    end
  end
end
