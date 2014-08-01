load "itunes.rb"
require "base64" 

class EditController < ApplicationController
#  caches_page :me
#  caches_page :homepage
  #cache_sweeper :terms_users_sweeper
  #@redirect_if_not_youser=true
  caches_page :term_more_info

  def find_users
    query = params[:query]
    if query.nil? or query.strip.empty?
      render(:inline=>"<div style='color:red'>you didn't enter anything!</div>")
      return
    end
    @users = User.find_by_sql(["select * from users where email_address=? and name<>'anon'",query])
    if @users.nil? or @users.empty?
      @users = User.find_by_sql("select * from users where name = '#{query}'")||[]
      @users += User.find_by_sql("select * from users where name<>'#{query}' and name like \"%#{query}%\" order by name")
    end
    @users=@users[0..19]
    render(:partial=>'user_results',:locals=>{:users=>@users})
  end

  def lastfm
    if params[:signup] and not @youser
      flash[:notice]="First, create an account."
      redirect_to basic_signup_url
    else
      must_be_known_user
    end
  end

  def itunes
    if params[:library] 
      @thenewfile = params[:library].path
      itunes = Itunes.new(logger,@metro_code+"_"+@youser.name)
      FileUtils.mv(@thenewfile, itunes.library_path)
      term_texts = itunes.extract_artists_from_user_file
      if (term_texts.size>0)
        @added_terms=Array.new
        @not_added_terms=Array.new
        term_texts.each{|term_text|
            logger.info("evaluating " + term_text) 
            x = false
            begin
              x = @youser.add_term_as_text(term_text,"itunes") 
            rescue
              logger.info("+++ error " + term_text) 
            end
#            term_text
            if x
              logger.info("added " + term_text) 
              @added_terms<<term_text
            else
              logger.info("didn't add " + term_text) 
              @not_added_terms<<term_text
            end
          }
        @youser.itunes_imported_at=DateTime.now
        num_added=@added_terms.size
        if num_added==0 
          flash[:error]="No new artists were found in the file."
          @youser.num_itunes_imports=0
          @youser.save_with_validation(false)
        else
          @youser.num_itunes_imports=num_added
          @youser.save_with_validation(false)
          expire_user_page(@youser)
          self.edit
          return
        end
      else
        flash[:error]="No artists were found in the file, or the file wasn't the right format."
      end
    end
    if params[:signup] and not @youser
      flash[:notice]="First, create an account."
      redirect_to basic_signup_url
    else
      must_be_known_user
    end
  end
  
  def itunes_handler

  end
  
  def lastfm_handler
    lastfm=Lastfm.new(logger)
    username = params[:username]
    if username.strip.empty?
      render(:inline=>'you must enter a username')
      return
    end
    if not lastfm.verify_username(username)
      render(:inline=>'last.fm doesn\'t recognize that username!')
      return
    end
    @youser.lastfm_username=username
    @youser.save
    term_texts = lastfm.import(@youser)
    flash[:notice]="The following were imported. You'll be notified when they come to #{@metro.capitalize}!<br>"+"<div style='padding:1em;'>#{term_texts.join(', ')}</div>"
    render(:inline=>"<script>location.href='/#{@metro_code}'</script>")
  end

  def term_more
    @term_id=params[:term_id]
    @term=Term.find(@term_id)
    @hype_tracks=Track.find_by_term(@term,'mp3','hype',10)
    render(:layout=>false)
  end

  def login
    super if request.post?
    @full_width_footer=true
  end

  def right_column
    mode=params[:mode]
    if mode=="edit"
      params[:terms_as_text]=@youser.terms_as_text_alpha if @youser_known
      render(:layout=>false,:action=>"edit_account_column.rhtml")
      return
    end
    if @youser_known
      @matched_terms=@youser.terms_with_future_matches
      matched_term_ids = Hash.new
      @matched_terms.each{|term| matched_term_ids[term.id]=true}
      @unmatched_terms = Array.new
      all_terms = @youser.terms
      #@unmatched terms is all_terms minus @matched_terms    
      all_terms.each {|term| @unmatched_terms<<term if not matched_term_ids[term.id]}
      @unmatched_terms.sort! {|x,y| x.text<=>y.text}
      render(:layout => false,:action => "view_account_column.rhtml")
    else
      render(:layout => false,:action => "create_account_column.rhtml",:youser_terms_as_text=>"foo")
    end
  end

  def add_remote
    add(true)
  end

  def add(remote=false)
      expire_youser_page
      @success=false
      term_text = params[:hidden_term_text]
      note = params[:note]
      note_entity = params[:note_entity]
      term_text = params[:term_text]||params[:youser_terms_as_text] if term_text.nil? or term_text.strip.empty?
      terms=Array.new
      begin
          term_text.chomp.split(/[\n,]+/).each { |t| #tokenize on CR
            next unless t
            t.strip!
            next if t.empty?
            terms<<t
          }
        end
        @message=""
        terms.each{|term|
          if term and @youser.add_term_as_text(term,note,note_entity) 
#            expire_term_fragment(term)
            @message+= "<span class='error' style='padding:0.25em'>#{term} added!</span><br>"
            @success=true
          else
            @message+= "<span class='error' style='padding:0.25em'>you already track #{term}!</span><br>"
          end
        }
      #expire_user_page(@youser)
      if remote
        if params[:hidden_term_text] and not params[:hidden_term_text].strip.empty?
          render(:inline=>'')
        else
          render(:inline=>@message) 
        end
      else
        flash[:notice]=@message
        redirect_to "/"
      end
  end
  
  def more
    render(:layout=>false)
  end
  
  def feature_handler
    match = Match.find(params[:feature][:match_id])
    feature = match.feature
    if feature
      feature.update_attributes(params[:feature])
    else
      feature = Feature.new(params[:feature])
      feature.user_id=@youser.id
      feature.username=@youser.name
      feature.editor_metro_code=@metro_code
    end

    # avoid dupes
    
    if params[:metro_specific]
      feature.metro_code=@metro_code
    end
    unless params[:dont_tweet]
      # tweet it
    end
    feature.save
    if feature.errors.empty?
      match.feature_id=feature.id
      match.save
      render(:inline=>'featured successfully!')
    else
      error_string= feature.render_errors.gsub('_',' ') 
      render(:inline=>error_string)
    end
#    expire_nightly_caches
  end
  
  def test
    render(:layout=>false)
  end
  
  def unfeature
    unless is_admin?
      flash[:admin]="you must be logged in as an admin to do that!"
    end
    Feature.delete(params[:id])
    flash[:notice]="you have successfully removed the feature!"
    redirect_to "/" 
  end

  def logged_in_search
    @term_text=request.raw_post
    @term_text= @term_text.chomp.split("&_=").first if @term_text            
    if @term_text&&@term_text.size<3
      render(:layout=>false)
      return
    end
    begin
      term=nil
      @term = Term.find_by_text(@term_text) 
      @match = @term.future_matches(1).first
      @hit_page=match.page
    rescue
    end
    
    @hit_page = Page.find(:first, :conditions => [ "status='future' and body like ?", 
                          "% #{@term_text} %"]) if not @match
    render(:layout =>false)
  end
    
  def explanation
    render(:partial =>"shared/explanation",:layout => false)
  end

  def explanation2
    render(:partial =>"shared/explanation2",:layout => false)
  end

  def my_related_terms
    _related_terms(false,10)
    render(:layout=>false)
  end

=begin
require "geoip"
c = GeoIP.new("/Users/chris/maxmind/GeoLiteCity.dat").city("76.24.220.14")


  def geolocate_
    require ‘geoip’
    c = GeoIP.new("~/maxmind/GeoLiteCity.dat").city()
    => [“www.nokia.com”, “147.243.3.83”, 69, “FI”, “FIN”, “Finland”, “EU”]
    c.country_code3
    => “FIN”
    c.to_hash
    => {:country_code3=>"FIN", :country_name=>"Finland", :continent_code=>"EU",
    :request=>"www.nokia.com", :country_code=>69, :country_code2=>"FI", :ip=>"147.243.3.83"}


    c = GeoIP.new(‘GeoLiteCity.dat’).city(‘github.com’)
    => [“github.com”, “207.97.227.239”, “US”, “USA”, “United States”, “NA”, “CA”,
    “San Francisco”, “94110”, 37.7484, -122.4156, 807, 415, “America/Los_Angeles”]
    >> c.longitude
    => -122.4156
    >> c.timezone
    => “America/Los_Angeles”
  end
=end

  def geolocate
    @lat=@lng=0
    if ENV['RAILS_ENV']=='development'
#      ip_address=params[:ip]
      ip_address="76.24.220.14"
    else
      ip_address = params[:ip]||request.remote_ip
    end
    #res = IpGeocoder.geocode(ip_address)
    c = geoip.city(ip_address)
    
    if !c
      render(:inline=>"fails "+@lat.to_s+@lng.to_s+@metros.inspect)
      return
    end
    hash = c.to_hash
    @lng = hash[:longitude]
    @lat = hash[:latitude]
#    render(:inline=>"::"+ip_address+":"+@lat.to_s+@lng.to_s )
#    return
    @metros = Metro.nearby_metros(@lat,@lng)||[]
    if @metros and not @metros.empty?
      args="{metros:["
      @metros.each_with_index{|metro,i|
        args+="," unless i==0
        args+="{code:'#{metro.code}',name:'#{metro.name}'}"
      }
      args+="]}"
      script = <<-SCRIPT
          pick_metro(#{args})
      SCRIPT
    else
      script="nada"
    end
    render(:inline=>script)
#    render(:inline=>@metros.first.code)
  end
  
  def sitemap
    headers["Content-Type"] = "text/xml"
    render(:layout=>false)
  end
  
  def footsy
    render(:inline=>'footsy')
  end

  def my_shows
    render(:partial=>'my_shows',:layout=>false)
  end

  def my_terms
    render(:partial=>'my_terms',:layout=>false)
  end

  def search
    @user=@youser
    @fragment=true
    terms_as_text=request.raw_post        
    @hits = Array.new
    @hit_counts = Array.new
    @hit_pages = Array.new
    @misses = Array.new
    @term_users = Hash.new
    terms = Array.new
    #terms_as_text=terms_as_text.split("&").first
    i=0
    # load all the users "matching" terms at once
    user_terms_texts=Hash.new
    @youser.terms.each{|term| user_terms_texts[term.text]=term} if @youser
    terms_as_text.chomp.split(/[\n,]+/).each { |term_text|
      term_text.strip!
      next if term_text=~ /&_=/
      next if term_text.size<3
      # find other users tracking this term
      pages=Array.new
      begin
        term = nil
        term = user_terms_texts[term_text] if @youser # first check if it is is in the hash, preloaded
        term = Term.find_by_text(term_text) if !term
        terms<<term if term
        matches = term.future_matches
        matches.each {|match|
          pages<<match.page
          } if matches
      rescue
        pages = Page.find_all_matching_term(term_text,11) if i<150 # don't go out of control searching for every one
      end
      #i=i+1
      if not pages.empty?
        page=pages.first
        #pages.each {|page|
#          puts term_text+":"+page.url(true)
          @hits<<term_text
          @hit_counts<<pages.size
          @hit_pages<<page
        #}
          #      if pages
          #         @hits<<term_text
          #        @hit_pages<<page
      else
        @misses<<term_text  if (term_text !~ /&_=/) && (term_text.size>=3) #ignore cruft
      end
    }
    setup_related_terms(terms,5)
    render(:layout => false)
  end
  
  def term_more_info
    render(:partial=>'shared/term_more_info',:locals=>params)
    return false
  end

  def term_more_info_popup
    render(:partial=>'shared/term_more_info_popup',:locals=>params+{:match_id=>params[:id],:term_id=>params[:term_id]})
    return false
  end


  def venues
    @by_venue=true
    cookies[:venue] = {
                        :value => 'true',
                        :expires => 360.days.from_now
                      }
    homepage
    render(:action=>'homepage')
  end

  def date
    @by_date=true
    cookies[:date] = {
                        :value => 'true',
                        :expires => 360.days.from_now
                      }
    homepage
    render(:action=>'homepage')
  end

  def use_calendar_nav_array
    @options_label='calndar_view'
    @nav_array=
      [
        {'your_SP_alerts'=>'add_bands_partial'},
        {'full_SP_calendar'=>'calendar_partial'},
        {'your_SP_calendar'=>'your_shows_partial'},
        {'friends'=>'friends_partial'}
      ]
    return @options_label,@nav_array
  end

  def use_list_nav_array
    @options_label='list_view'
    @featured_matches=Match.current_with_feature(-1,"features.updated_at desc")
    if @featured_matches and @featured_matches.size>0
      @nav_array=
        [
          {'editors_QT__SP_picks'=>'featured_partial'},
          {'popular'=>'popular_partial'},
          {'new'=>'new_partial'}
        ]
    else
      @nav_array=
        [
          {'popular'=>'popular_partial'},
          {'new'=>'new_partial'}
        ]
    end
    return @options_label,@nav_array,@featured_matches
  end

  def use_list_nav_array_no_editors_picks
    @options_label='list_view'
    @nav_array=
      [
        {'popular'=>'popular_partial'},
        {'new'=>'new_partial'}
      ]
    return @options_label,@nav_array
      
  end

  def venues_partial
    use_calendar_nav_array
    render(:layout=>false)
  end

  def scratch
    use_calendar_nav_array
  end

  def calendar_partial
    use_calendar_nav_array
    render(:partial=>'calendar_partial',:layout=>false)
  end
  
  def friends_partial
    use_calendar_nav_array
    render(:partial=>'friends_partial',:layout=>false)
  end

  def feed_partial
    use_calendar_nav_array
    render(:layout=>false)
  end


  def add_bands_partial
    render(:partial=>'add_bands_partial')
  end

  def your_shows_partial
    render(:partial=>'your_shows_partial')
  end

  def new_partial
    render(:partial=>'new_partial')
  end

  def popular_partial
    render(:partial=>'popular_partial')
  end

  def featured_partial
    render(:partial=>'featured_partial')
  end

  def beta_signup
    if request.post?
      unless params[:email_address] and params[:email_address]=~/@/
        flash[:error]="you must enter a valid email address!"
        return
      end
      contact = Contact.new
      contact.email_address=params[:email_address]
      contact.user_id=@youser.id if @youser
      contact.save
      flash[:notice]="thanks! you should get an email with the beta URL within a few weeks :)"
    end
  end



  def combined
    @by_combined=true
    cookies[:combined] = {
                        :value => 'true',
                        :expires => 360.days.from_now
                      }
    homepage
    render(:action=>'homepage')
  end

  def lala_popup
    render(:layout=>false)
  end

  def mushroom
    @by_mushroom=true
    cookies[:mushroom] = {
                        :value => 'true',
                        :expires => 360.days.from_now
                      }
    homepage
    render(:action=>'homepage')
  end
  
  def co1
    flash[:notice]="You've successfully signed for email alerts! <br>No further action is necessary. But you can always come back here to add more bands!"
    redirect_to('co');
  end

  def co
    @metro_code='boston'
    @hide_header=@hide_footer=true
    @jquery=true
    @days_to_show = params[:id]||60
    @offset = params[:offset].to_i 
    @days_to_show=180 if @days_to_show=='all'
    @days_to_show=@days_to_show.to_i
    @source = Source.new
    @source.locale=@metro_code
    @not_in_a_city=true
    render(:layout=>'bostoncom')
  end  

  def co_signup
    @metro_code='boston'
    @hide_header=@hide_footer=true
    @jquery=true
    @days_to_show = params[:id]||60
    @offset = params[:offset].to_i 
    @days_to_show=180 if @days_to_show=='all'
    @days_to_show=@days_to_show.to_i
    @source = Source.new
    @source.locale=@metro_code
    @not_in_a_city=true
    render(:layout=>'bostoncom')
  end  

  def concerts_homepage
    @view=:calendar
    homepage
    render(:action=>'homepage')
  end

  def homepage
    @jquery=true
    @days_to_show = params[:id]||60
    @offset = params[:offset].to_i 
    @days_to_show=180 if @days_to_show=='all'
    @days_to_show=@days_to_show.to_i
    @full_width_footer=true
    @source = Source.new
    @source.locale=@metro_code
  end  

  def just_calendar
    @full_width_footer=true
    @source = Source.new
    @source.locale=@metro_code
    @days_to_show = params[:id]||1
    @offset = params[:offset].to_i 
    @days_to_show=90 if @days_to_show=='all'
    @days_to_show=@days_to_show.to_i
    @break_between_days=true
    render(:partial=>"shared/calendar_with_images",:layout=>false)
  end

  def homepage2
    @full_width_footer=true
    @source = Source.new
    @source.locale=@metro_code
    @days_to_show = params[:id]||1
    @offset = params[:offset].to_i 
    @days_to_show=90 if @days_to_show=='all'
    @days_to_show=@days_to_show.to_i
    @break_between_days=true
  end

  
  def me
    redirect_to "/homepage" and return if not @youser
    @full_width_footer=true
#    @user=User.find_by_name(params[:username])
#    render_text 'unknown user!' and return if not @user
#    render_text 'not your page!' and return if not @youser or (@youser.id!=@user.id)
#   params[:terms_as_text]=@youser.terms_as_text_alpha if @youser_known
#    setup_calendar_collated(@youser,nil,42)
#    matches=Match.recommended_matches_within_n_days_for_user(42,@youser)
#    @recommended_days,@recommended_matches=matches2calendar(matches)
  end

  def do_page
    return if @redirect_if_youser and @youser_known
#    params["met[code]"]=@metro_code
    @source = Source.new
    @source.locale=@metro_code
    params[:terms_as_text]=@youser.terms_as_text_alpha if @youser_known
    setup_calendar(nil,nil,42)
    render(:action=>"index")
  end
  
  def homepage_signup_link
    set_cookie('metro_code',"")
    redirect_to(:homepage)
  end
  
  def signup
    if @youser
      if params[:term_text]
        add
        return
      else
        if params[:redirect] and params[:redirect]=~/lastfm/
          flash[:notice]="Step 2. Import your last.fm artists"
          redirect_to params[:redirect]
        else
          redirect_to "/"
        end
      end
    end
    @full_width_footer=true
  end

  def edit
    return if not must_be_known_user("First, log in.")
    render(:action=>'edit',:layout=>true)
  end


  def handle_invitations(user)
    # see if there is an invitation cookie in existence. 
    # if so, get the invitation id and mark the invitation as accepted and date tit
    # then create reciprocal recommendations between the inviter and invitee
    begin
      invitation_ticket=cookies[:invitation_ticket]
      invitation=nil
      if invitation_ticket
          invitation_id_multiplied = decode64(invitation_ticket)
          invitation_id_multiplied = Integer(invitation_id_multiplied)
          invitation_id = invitation_id_multiplied/1024
          invitation = Invitation.find(invitation_id)
      end
      return if not invitation
      return if invitation.to_user_registered_at # don't allow a double-accept
      invitation.to_user_registered_at=DateTime.now
      invitation.to_user_id=user.id
      invitation.save!
    
      # create a rr from the from to the to
        rr=RecommendeesRecommenders.new
        rr.recommendee_id=invitation.from_user_id
        rr.recommender_id=invitation.to_user_id
        rr.save
        rr=RecommendeesRecommenders.new
        rr.recommendee_id=invitation.to_user_id
        rr.recommender_id=invitation.from_user_id
        rr.save
        expire_user_page(rr.recommendee)
        expire_user_page(rr.recommender)
          # send inviter an email saying he has a new recommendee ...
          NewRecommendeeMailer::deliver_new_recommendee(rr)      
      rescue Exception
        logger.info $!
        return
      end
      @is_recommendee=true    
  end
  
  def authenticate_client
#    logger.info("session[:auth]: #{session[:auth]}")
#    logger.info("params[:n1]: #{session[:n1]}")
#    logger.info("params[:n2]: #{session[:n2]}")
    logger.info("params[:auth]: #{params[:auth]}")
#    Integer(session[:auth])==Integer(params[:auth])
    params[:auth]=="auth2"
  end

  def random_password
    words= %w(red yellow blue green orange purple violet brown black white)
    "#{words[rand(words.size)]}#{words[rand(words.size)]}#{words[rand(words.size)]}"
  end
  
  def handle_user_tickets(user,body,match_id)
    uto = UserTicketOffer.new
    match = Match.find(match_id)
    uto.match_id = match_id
    uto.match_description = match.dropdown_description
    uto.body = body
    uto.user_id = user.id
    uto.save
    flash[:notice] = "Your posted successfully to have/want tickets! You can <span class='underline'><a href= '/#{@metro_code}/have_want_tickets?own_only=true'>manage your submitted tickets</a>.</span>"
    expire_term_fragment(match.term) 
  end

  @@co_hash=
  {
    'bostoncom'=>'co'
  }
  
  def remote_post
    co = params[:co]
    if request.post?
      if not @youser_logged_in and not authenticate_client
        render(:inline=>"You must enter a username")
        return
      end
      note = params[:note]
      # register the user and log him or her in ...
      basic=false
      if !@youser_logged_in
        if params[:youser][:registration_type]=="basic"
          basic=true
          params[:youser][:name]="anon" #params[:youser][:email_address].gsub(/[^\w]/,"")
          params[:youser][:password]=random_password
          params[:youser][:email_address]=params[:email_address] if not params[:youser][:email_address]
        end
        @youser = User.new(params[:youser])
        @youser.metro_code=@metro_code
        @youser.registered_on=DateTime.now

        referer=cookies[:ref]
        referer =~ /((\w+)?\.(\w+)?\.(edu|com|org|fr|net|uk)|localhost:3000)/ if referer
        if $&
          @youser.referer_domain=$&
          @youser.referer_path=$'
        else
          @youser.referer_path=referer
        end
        begin
          @youser.save!
          if basic
             @youser.name="anon-#{@youser.id}"
             @youser.save!
          end
            
          terms_as_text = params[:youser][:terms_as_text]||""
          params[:more_terms_as_text].each_key{|key| terms_as_text+="\r\n#{key}"} if params[:more_terms_as_text]
          logger.info "terms_as_text:#{terms_as_text}"
          @youser.terms_as_text=terms_as_text
          @youser.update_terms(note)
          begin
            WelcomeMailer::deliver_welcome(self,@youser)  unless ENV['RAILS_ENV']=='development'
          rescue =>e
            logger.info("+++ error sending email:"+e.message+"\n"+e.backtrace.join("\n"))
          end
          login_user(@youser,false)
          cookies['calndar_view']='your_SP_alerts'
          if params[:redirect_url] && !params[:redirect_url].empty?
            render(:inline=>"<script>location.href='<%=params[:redirect_url]%>';</script>",:layout=>false)
            return
          else
            render(:inline=>"<script>alert('Successfully signed up. Now add some more bands!');location.href='/';</script>",:layout=>false)
          end
          return
        rescue =>e
          logger.info(e.message+"\n"+e.backtrace.join("\n"))
          errors = @youser.render_errors
          if errors
            error_string=errors.gsub('_',' ') 
            error_string+='<script>_$("#submit").attr("disabled","")</script>'
          end
          error_string="error: #{e.message.downcase}" if errors.empty? 
          
#          error_string="unknown error - please error us about this: <a href='mailto:chris@tourfilter.com'>chris@tourfilter.com</a>" if error_string.nil? or error_string.strip.empty?
          set_metro_code('')
          render(:inline=>error_string)  
        end
      else #user is logged in, just save the terms
        #logger.info("terms_as_text"+params[:user][:terms_as_text])
        terms_as_text=params[:terms_as_text]
        terms_as_text+="\r\n"+params[:more_terms_as_text].each_key{|key|key}.join(',') if params[:more_terms_as_text]
        logger.info terms_as_text
        @youser.terms_as_text=terms_as_text
        @youser.do_save
        expire_user_page(@youser)
#        flash[:notice]= 'Your band list was updated!'
      end
   
    end
  end

end
