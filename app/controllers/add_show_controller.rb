class AddShowController < ApplicationController  

  def auto_complete_for_venue_name
    @places = Place.find_in_metro_like_name(@metro_code,params[:venue][:name])
    render :inline => '<%= content_tag(:ul, @places.map { |place| content_tag(:li, h("#{place.name.downcase}")) }) %>'
  end

  def submit_show
    return if not must_be_known_user
    @num_shows = ImportedEvent.count_by_sql("select count(*) from imported_events where user_id=#{@youser.id}") if @youser
    use_full_width_footer
  end

  def delete_submitted_show
    event=ImportedEvent.find(params[:id]) rescue nil
    if not event
      flash[:error]="unrecognized id"
      redirect_to "/user_submitted_shows"
      return
    else
      if event.user_id!=@youser.id
        flash[:error]="permission error"
        redirect_to "/user_submitted_shows"
        return
      end
      if event.status=='made_match'
        flash[:error]="status error"
        redirect_to "/user_submitted_shows"
        return
      end
      ImportedEvent.delete_all("id=#{event.id}")
      flash[:notice]="show deleted successfully!"
      redirect_to "/user_submitted_shows"
      return
    end
  end

  def all_user_submitted_shows
    use_full_width_footer
    return if not must_be_known_user
  end

  def user_submitted_shows
    use_full_width_footer
    return if not must_be_known_user
  end
  
  def index
    submit_show
  end
  
  def validate
    @errors=Array.new
    begin
      Date.new(Integer(params[:year]),Integer(params[:month]),Integer(params[:day]))
    rescue
      @errors<<"invalid date" 
    end
    @errors<<"must enter a (longer) description" unless params[:body] and params[:body].strip.size>1
    @errors<<"must enter a (longer) venue name" unless params[:venue][:name] and params[:venue][:name].strip.size>3
    @errors<<"invalid character" if params[:venue][:name]+params[:body]+params[:address]+params[:user_event][:url]=~HTML_REGEXP
#    @errors<<"must select a metro" unless params[:object][:metro_code] and params[:object][:metro_code].strip.size>3
    return @errors.empty?
  end


  def handle_direct_submit(event)
    url=params[:url]

    term = find_or_create_term(params[:body])
    match=Match.new
    match.venue_id=event.venue.id
    match.venue_name=event.venue.name
    match.term_id=term.id 
    match.status='notified'
    match.time_status='future'
    match.user_id=@youser.id
    match.source="admin"
    match.date_for_sorting=Date.new(Integer(params[:year]),Integer(params[:month]),Integer(params[:day]))    
    match.day=Integer(params[:day])
    match.month=Integer(params[:month])
    match.year=Integer(params[:year])
    match.imported_event_id=event.id
    match.save    
    @youser.add_term(term)
    #email = MatchMailer::deliver_match(@metro_code,match) 

    event.status='made_match' #effectively this process has been done, like it's done in the daemon
    event.save
    
    
  end

  def find_or_create_term(text)
    term = Term.find_by_text(text)
    return term if term
    term = Term.new
    term.text=text
    term.save
    return term
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
      venue.state=Metro.find_by_code(@metro_code).state
      venue.save
      mv = MetrosVenue.new  
      mv.metro_code=@metro_code#params[:object][:metro_code]
      mv.venue_id=venue.id
      mv.save
    end
    return venue
  end

  def handler
    unless validate
      render(:layout=>false)
      return
    end
    if params[:submit]=='cancel'
      render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
      return
    end
    direct_admin_submit=false
    if params[:venue][:direct_submit]=='true'
      if not is_admin?
        @errors<<"must be admin!"
        render(:layout=>false)
        return
      else
        direct_admin_submit=true
      end
    end
    event = ImportedEvent.new
    event.source='user'
    event.level='primary'
    event.status='new'
    event.user_id=@youser.id
    event.username=@youser.name
    event.user_metro=@metro_code
    event.date=Date.new(Integer(params[:year]),Integer(params[:month]),Integer(params[:day]))
    event.url=params[:url]
    event.body=params[:body]
    venue = find_or_create_venue(params[:venue][:name],params[:address])
    event.venue_name=venue.name
    event.venue_id=venue.id
    dupe =event.find_dupe
    if dupe and not dupe.empty?
      @errors<<"duplicate event!"
      render(:layout=>false)
      return
    end
    event.save
    if direct_admin_submit
      handle_direct_submit(event) 
      term_url=url("/#{event.body}")
      render(:inline=>"Show submitted. It will appear on the site within 24 hrs, once caches have cleared. You should be able to see it here: <a href='#{term_url}'>#{event.body}</a>",:layout=>false)
    else
      render(:inline=>"Show submitted! An editor will review this within 24 hours or so; you will get an email letting you know what happened. <span class='underline'><a href= '/#{@metro_code}/user_submitted_shows'>view your submitted shows</a></span>",:layout=>false)
    end
    
  end

  def handler_
    if params[:button]=~/Done/
      flash[:notice]="Registration complete!"
      render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
      return
    end
    @youser.update_attributes(params[:youser])
    @youser.registration_type="normal" and @youser.save if @youser.name!="none"
    if @youser.errors.empty?
      flash[:notice]="You have successfully changed your settings!" 
      flash[:notice]="Your new profile has been created. Registration complete!" if params[:prior_referer]=~/welcome/
      ChangedSettingsMailer::deliver_changed_settings(@youser)
      expire_youser_page
      render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
      return false
    else
      render(:layout => false)
    end
  end  

end
