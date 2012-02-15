# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'rubygems'
require 'fileutils'
require 'digest/md5'

#require 'net/https'

class ApplicationController < ActionController::Base

#  caches_page :bands_wrapper
  
  SALT="BRUN TAXMAN"
  before_filter :convert_to_new_url_structure_1
  before_filter :convert_to_new_url_structure_2
  before_filter :initialize_metro#, :except=>:login_header
  before_filter :connect_to_the_correct_database
  before_filter :initialize_user, :except => :login
  before_filter :mark_time
  before_filter :ensure_www
  before_filter :set_tracking_cookie,:except => :track_click
  before_filter :set_referer_cookie,:except => :track_click    
  after_filter :log_page_view, :except => :track_click
  
  @show_venues=false
  @@metro_map=nil

  def redirect_to(options)
    if options.is_a? Hash
      options[:controller]="#{@metro_code}/#{options[:controller]}" if options[:controller]
    elsif options.is_a? String and options =~/^\//
      options="/#{@metro_code}#{options}"
    end
    super(options)
  end

  def redirect_to(options,*parameters_for_method_reference)
    if options.is_a? Hash
      options[:controller]="#{@metro_code}/#{options[:controller]}" if options[:controller]
    elsif options.is_a? String and options =~/^\//
      options="/#{@metro_code}#{options}"
    end
    super(options,*parameters_for_method_reference)
  end

  def metro_code
    @metro_code
  end

  def metro
    @metro
  end
  
  def domain_stub
    @domain_stub
  end
  
  def domain
    if ENV['RAILS_ENV']=='development'
      return "www.tourfilter.local:3000"
    else
      return "www.tourfilter.com"
    end
  end

  def local_request?
    false
    #true
  end

  @@metros = nil
  def make_metro_map
    logger.info("make_metro_map")
    if @@metros
      @metros=@@metros
    else
      @metros = Metro.find_all
    end
    map=Hash.new
    @metros.each{|metro|
#      logger.info("metro: #{metro.code}")
      map[metro.code]=metro
    }
    @@metros=@metros
    map
  end
  
  def created(object,info=nil)
    Event.created(@youser,object,info)
  end

  def updated(object,info=nil)
    Event.updated(@youser,object,info)
  end

  def deleted(object,info=nil)
    Event.deleted(@youser,object,info)
  end

  def viewed(object,info=nil)
    Event.viewed(@youser,object,"view",info)
  end

  def connect_to_the_correct_database
    begin
      logger.info("metro_code in connect: #{@metro_code}")
      @metro_code||="boston"
      database_code=@metro_code
      if database_code=="facebook" or database_code=="search"
        if ENV['RAILS_ENV']=='development'
          database_code="shared"
        else
          database_code="all"
        end
      end
#      logger.info("database_code: #{database_code}")
      ActiveRecord::Base.establish_connection(
        :adapter  => "mysql",
        :host     => "127.0.0.1",
        :username => "chris",
        :password => "chris",
        :database => "tourfilter_#{database_code}"
        )
    rescue => e
      log_error(e)
      puts "error!"
    end
  end
  
  def initialize_metro
    SETTINGS['date_type']='us'
#    logger.info("SETTINGS.date_type: #{SETTINGS['date_type']}")
    @metro = "Boston"
    @metro_code = "boston"
#    @metro_map = Hash.new
    @metro_map=make_metro_map
#    @metro_map["westernmass"] = "Western Mass"
#    @metro_map["boston"] = "Boston"
#    @metro_map["newyork"] = "New York"
    request.host =~ /(\w+)\.(tourfilter\.(?:org|com|net|local))/
    @domain_stub=$2
    subdomain=$1
    url_metro_code=params[:metro_code]
    if not @metro_map[params[:metro_code]]
      url_metro_code=subdomain
    end
#    logger.info("params[:metro_code]: #{params[:metro_code]}")
#    logger.info("subdomain: #{subdomain}")
#    logger.info("url_metro_code: #{url_metro_code}")
    if /^\/search/=~request.request_uri
      @not_in_a_city=true
      @metro_code="search"
      @metro_name="all-cities search"
      return
    end
    if /^\/facebook/=~request.request_uri
      @not_in_a_city=true
      @metro_code="facebook"
      @metro_name="facebook"
      return
    end

    if @metro_map[url_metro_code] and not @metro_map[url_metro_code].name.empty?
      @metro = @metro_map[url_metro_code].name
#      logger.info("@metro: #{@metro}")
      @num_places = @metro_map[url_metro_code].num_places 
#      logger.info("num_places: #{@num_places}")
      @metro_active = @metro_map[url_metro_code].active?
      @metro_code=url_metro_code
#      logger.info("@metro_code: #{@metro_code}")
    else
#      logger.info("request.host: #{request.host}")
      if url_metro_code=="www" or request.host =~ /^192.168.1/
        @subdomain_is_www=true
        @metro_active=@metro_map["boston"].active?
        @num_places=@metro_map["boston"].num_places
        return true
      end
      redirect_to "http://www.tourfilter.com#{request.path}"
      return false    
    end

#    if url_metro_code=="boston"
#      new_domain = request.host.gsub(/boston/,"www")
#      redirect_to "http://#{new_domain}#{request.path}"
#      return false    
#    end

    if @metro_code=="london" or @metro_code=="melbourne" or @metro_code=="dublin"
      SETTINGS['date_type']='uk'
    end
    return true
  end
  
  def error(text)
    flash[:error]=text
    render(:controller=>"error")
  end
  
  def convert_to_new_url_structure_1
    # get the subdomain and the path_code
    request.host =~ /(\w+)\.(tourfilter\.(?:org|com|net|local))/
    domain_stub=$2
    subdomain=$1
    path = request.path
    logger.info("request.path in convert_1: #{request.path}")
    puts("subdomain in convert_1: #{subdomain}")
    path_code = (request.path.scan(/[^\/]+/)||[""]).first
    metro_map = make_metro_map
    metro_map["facebook"]=true
    metro_map["search"]=true
    logger.info("subdomain in convert_1: #{subdomain}")
    logger.info("path_code in convert_1: #{path_code}")
    puts("subdomain in convert_1: #{subdomain}")
    puts("path_code in convert_1: #{path_code}")
    # e.g. if the url is "www" and the path doesn't start with "/boston" or "/newyork" etc.
    if not metro_map[subdomain] and not metro_map[path_code]
      redirect_to("http://#{domain}/boston#{request.path}",false)
      return false
    end
    return true
  end

  def convert_to_new_url_structure_2
    # get the subdomain and the path_code
    request.host =~ /(\w+)\.(tourfilter\.(?:org|com|net|local))/
    domain_stub=$2
    subdomain=$1
    path = request.path
    logger.info("request.path in convert_2: #{request.path}")
    path_code = (request.path.scan(/\[^\/]+/)||[""]).first
    metro_map = make_metro_map
    metro_map["facebook"]=true
    metro_map["search"]=true
    logger.info("subdomain in convert_2: #{subdomain}")
    logger.info("path_code in convert_2: #{path_code}")
    puts("subdomain in convert_2: #{subdomain}")
    puts("path_code in convert_2: #{path_code}")
    if subdomain!="www"
      if request.path=~/^\/facebook/ or request.path=~/^\/search/
        redirect_to("http://#{domain}#{request.path}",false)
      else 
        redirect_to("http://#{domain}/#{subdomain}#{request.path}",false)
      end
      return false
    end
    return true
  end



  def ensure_www
    return true if request.host=~/localhost|tourfilter\.(com|local)|^192.168.1/
    redirect_to "http://www.tourfilter.com#{request.path}"
    return false     
  end
  
  def must_be_admin
    return false if not must_be_known_user
    if !@youser.privs||@youser.privs!="admin"
      flash[:error]="You don't have permission to access that page!"
      redirect_to '/'
      return false 
    end
    return true
  end

  def must_be_known_user_no_message
    if !@youser_known
      redirect_to :controller => 'edit'
      return false
    end
    return true
  end

  def must_be_known_user
    if !@youser_known
      flash[:error]="You must be logged in to do that!"
      redirect_to :controller => 'edit'
      return false
    end
    return true
  end
  
  def mark_time
    @before = Time.new
    return true
  end
  
  def get_cookie(name)
    cookies[name]
  end
  
  def set_tracking_cookie
    # generate permanent tracking cookie based on session_id
    cookies[:psid] = {
                          :value => String(session.session_id),
                          :expires => 10.years.from_now,
                          :path => "/#{@metro_code}"
                        }     if not cookies[:psid]
    return true
  end
  
  def set_referer_cookie
    # extract referer_domain and put that in the cookie if the user is not logged in
    referer = request.env['HTTP_REFERER']
    return true if not referer or referer.empty?
    logger.info("SETTING REFERER COOKIE TO #{referer}")
    cookies[:ref] = {
                          :value => String(referer),
                          :expires => 10.years.from_now,
                          :domain => ".tourfilter.com",
                          :path => "/"
                      } if referer !~ /tourfilter\.(com|local)/
#                      } if referer !~ /^http\:\/\/\w{1,32}\.tourfilter\.(com|local)/
    return true
  end
  
  def matches2calendar(_matches)
    days=Array.new
    matches=Hash.new
#    matched_term_ids=Hash.new
    _matches.each{|match|
      if not matches[match.date_for_sorting]
        days<<match.date_for_sorting 
        matches[match.date_for_sorting]=Array.new
      end
      matches[match.date_for_sorting]<<match
#      matched_term_ids[match.term_id]=true
    }
    return [days,matches]
  end

  def bands_wrapper
    render_component(:controller=>"bands",:action=>"bands",:id=>params[:id],:params=>{:metro_code=>@metro_code})
  end

  def setup_calendar(user=nil,num=90)
    @days=Array.new
    @matches=Hash.new
#    places = Place.find_all_active
    _matches=Array.new
    _matches=Match.matches_within_n_days_for_user(num,user)
    @matched_term_ids=Hash.new
    # strip "the" off beginning of matches
    # don't list same match twice on the same day
    day_terms=Hash.new
    _matches.each{|match|
      term_text=Term.normalize_text(match.term.text)
      next if day_terms["#{match.date_for_sorting}:#{term_text.downcase}"]
      day_terms["#{match.date_for_sorting}:#{term_text.downcase}"]=true
      if not @matches[match.date_for_sorting]
        @days<<match.date_for_sorting 
        @matches[match.date_for_sorting]=Array.new
      end
      @matches[match.date_for_sorting]<<match
      @matched_term_ids[match.term_id]=true
    }
    @matches.each_key{|key|
      @matches[key].sort!{|x,y|
        Term.normalize_text(x.term.text).downcase<=>Term.normalize_text(y.term.text).downcase
      }
    }
    [@days,@matches]
  end

  
  def log_page_view(url=nil,referer=nil,source="ruby")
    return if ENV['RAILS_ENV']=='development'
    page_view = PageView.new
    if @youser
      page_view.youser_id = @youser.id 
    else
      page_view.youser_id = -1
    end
    page_view.ip_address = request.remote_ip
    if url==nil
      page_view.url = request.path
    else
        url =~ /((\w+)?\.(\w+)?\.(edu|com|org|fr|net|uk|local)|localhost:3000)/
        if $&
          page_view.domain=$&
          page_view.url=$'
        else
          page_view.url=url
        end
    end
    referer=request.env['HTTP_REFERER'] if not referer
    # use 'original' referer in place of local referers ...
    referer_domain=nil
    if referer
      #extract domain from referer
      referer =~ /((\w+)?\.(\w+)?\.(edu|com|org|fr|net|uk|local)|localhost:3000)/
      if $&
        page_view.referer_domain=$&
        page_view.referer=$'
      else
        page_view.referer=referer
      end
    end
    original_referer=cookies[:ref]
    if original_referer
      #extract domain from referer
      original_referer =~ /((\w+)?\.(\w+)?\.(edu|com|org|fr|net|uk|local)|localhost:3000)/
      if $&
        page_view.original_referer_domain=$&
        page_view.original_referer_path=$'
      else
        page_view.original_referer_path=referer
      end
    end
    page_view.session_id = session.session_id
    page_view.perm_session_id = cookies[:psid]
    page_view.user_agent = request.env['HTTP_USER_AGENT']
#    page_view.referer = referer
#    page_view.referer_domain=referer_domain
    @before||Time.new
    page_view.time_to_render = Time.new-(@before||Time.new)
    page_view.source=source
    if request.raw_post
      form_contents=request.raw_post.gsub(/[\r\n]/,"|") 
      form_contents.sub!(/(password=)[\w\d]{1,16}/,"\1*****")
      page_view.form_contents=form_contents
    end
    page_view.save
    return true
  end
  
  def record_visit
    # once per session, record the time and user-agent of the user in the user-record
    visit_recorded=session[:visit_recorded]
    if visit_recorded!="1"
      session[:visit_recorded]="1"
      @youser.last_user_agent=request.user_agent
      @youser.last_visited_on=DateTime.now
      @youser.save
    end
      
  end
  
  def generate_cookie_hash(youser_id)
#    logger.info("youser_id: #{youser_id}")
#    logger.info("request.remote_ip: #{request.remote_ip}")
    hash = Digest::MD5.hexdigest("#{youser_id}|#{request.remote_ip}|#{@metro_code}|#{SALT}")
#    logger.info("hash: #{hash}")
    hash
  end
  
  def initialize_user
    @youser_known = false
    @youser_logged_in = false
    cookie_user_id = cookies[:"#{@metro_code}_user_id"]
    id_hash = cookies[:"#{@metro_code}_id_hash"]
#    logger.info("id_hash: #{id_hash}")
#    logger.info("cookie_user_id: #{cookie_user_id}")
    session_user_id = session[:"#{@metro_code}_user_id"]
    if !session_user_id.nil?
#      logger.info("authenticate.session.userid.found: #{session_user_id}")
      @youser_known = true
      @youser_logged_in = true
      @youser_id = session_user_id
    end
    if cookie_user_id and id_hash
 #     logger.info("authenticate.cookie.userid.found: #{cookie_user_id}")    
#      session[:"#{@metro_code}_user_id"]=cookie_user_id
      compare_hash = generate_cookie_hash(cookie_user_id)
      if id_hash!=compare_hash
#        logger.info("cookie hash compare failed")
        cookies[:"#{@metro_code}_user_id"]=""
        cookies[:"#{@metro_code}_id_hash"]=""
        @youser_known = false
        @youser_logged_in = false
        @youser_id = nil
      else
        @youser_known = true  
        @youser_logged_in = true
        @youser_id = cookie_user_id
      end
    end
    begin
      if @youser_known
        @youser = User.find(@youser_id)
        record_visit
      end
    rescue      
      logout
      return true
    end
    return true
  end
  
  def login
    login_with_name_password(params[:name],params[:password])
  end
  
  def login_user (user,redirect=true)
    login_with_name_password(user.name,user.password,redirect)
  end
  
  def login_with_name_password(name,password,redirect=true)
    if request.post?
      @youser = User.find_by_name_and_password(name,password)    
      if @youser.nil?
        @youser= User.find_by_email_address_and_password(name,password)
      end
      if @youser.nil?
        flash[:notice] = 'Unknown username and/or password. Did you <a href="/#{@metro_code}/lost_password">forget your password?</a>'
        redirect_to request.env['HTTP_REFERER'] # just refresh the page
        return
      else
        @youser.last_logged_in_on=DateTime.now
        @youser.save 
#       domain="#{@metro_code}.#{@domain_stub}" 
#       domain=@domain_stub if @youser.privs=='admin' 
        session[:"#{@metro_code}_user_id"] = @youser.id
        cookies[:"#{@metro_code}_user_id"] = {
                              :value => String(@youser.id),
#                              :domain => domain,
                              :expires => 90.days.from_now,
                              :path => "/#{@metro_code}"
                            }
        logger.info("cookies.inspect:"+cookies.inspect)
        logger.info("@metro_code:"+@metro_code)
        id_hash= generate_cookie_hash(@youser.id)
        cookies[:"#{@metro_code}_id_hash"] = {
                              :value => String(id_hash),
                              :expires => 90.days.from_now,
                              :path => "/#{@metro_code}"
                            }
      end
#      if request.env['HTTP_REFERER'] =~ /edit/
#        redirect_to(:controller => "home")
#      else
        flash[:notice] = 'Logged in!'
#        redirect_to request.env['HTTP_REFERER'] if redirect # just refresh the page
       redirect_to "/" if redirect
#      end
    end
  end
  
  def logout
    session[:"#{@metro_code}_user_id"] = nil;
    cookies[:"#{@metro_code}_user_id"] = {
                          :value => "",
                          :expires => 90.days.from_now,
                          :path => "/#{@metro_code}"
                        }
    cookies[:"#{@metro_code}_id_hash"] = {
                          :value => "",
                          :expires => 90.days.from_now,
                          :path => "/#{@metro_code}"
                        }
    flash[:notice] = 'Logged out!'
    redirect_to "/homepage"
  end

  def logout_test
    output="logout: #{@metro_code} #{@metro_code}_user_id #{@metro_code}_id_hash<br><br><br>"
    output+="cookies.inspect before logout: #{cookies.inspect}<br><br><br>"
    session[:"#{@metro_code}_user_id"] = nil;
    cookies.delete :"#{@metro_code}_user_id"
    cookies.delete :"#{@metro_code}_id_hash"
    cookies.delete "#{@metro_code}_user_id"
    cookies.delete "#{@metro_code}_id_hash"
    output+="cookies.inspect after logout: #{cookies.inspect}<br><br><br>"
    render(:inline=>output)
  end

  
  def expire_main_rss_pages
    expire_page(:controller => "rss", :action=> "rss")
    render(:inline => 'public rss page cache expired!')
  end

  def expire_main_ical_page
    expire_page(:controller => "ical", :action=> "ical")
    render(:inline => 'public ical page cache expired!')
  end
  
  def expire_browse_page
    expire_page(:controller => "browse", :action=> "index")
    render(:inline => 'browse-page cache expired!')
  end

  # expire_user_page - invalidate the l1-cache for this user ... (eg "/users/chris")
  def expire_youser_page
    expire_user_page(@youser)
  end
  
  def expire_user_page(user)
    return if !user
    logger.info("expire_page for user")
    expire_page(:controller => "users", :action=> user.name)
    expire_page(:controller => "me", :action=> user.name)
    logger.info("expire_page for badge")
    expire_page(:controller => "badge", :action=> user.name)
    logger.info("expire_fragment me/username")
    expire_action({:controller=>"me",:action=>user.name.downcase})
    
#    expire_fragment(%r{/me/#{user.name.downcase}})
#    begin
#      to_delete= "#{RAILS_ROOT}/public/badge/#{user.name}"
#      puts "rm -rf #{to_delete}"
#      FileUtils.rm_rf(to_delete) -- too timeconsuming!
#    rescue
#    end
  end

  # expire_term_page - invalidate the l1-cache for this term ... (eg "/bands/Sparklehorse")
  def expire_term_page(term)
    return if !term
    expire_page(:controller=>"/",:action=>term.url_text)
  end

  def expire_public_recommendation_caches
    expire_recommendation_caches
    render(:inline => 'public recommendation caches expired!')
  end
  
  def expire_public_calendars_caches
    expire_fragment(%r{/edit/terms_by_place})
    expire_fragment(%r{/calendar})
    expire_fragment(%r{/edit/homepage_calendar})
    expire_fragment(%r{/ical/ical})
    expire_page(:controller => "calendar", :action=>"index")
    expire_page(:controller => "edit", :action=>"index")
    expire_page(:controller => "/", :action=>"homepage")
    render(:inline => 'public calendars caches and homepage expired!')
  end

  def expire_recent_users_caches
    expire_fragment(%r{/edit/recent_users/.*})
  end

  def expire_recommendation_caches(recommendation=nil)
    expire_fragment(%r{/home/recommendations})
    expire_term_fragment(recommendation.match.term) if recommendation
  end
  
  # expire_term_fragment - invalidate the l2 bandlist term fragment, the l2 calendar term fragment and all l1-user and l1-band page caches that contain it.
  # also expire the me page page-level cache.
  def expire_term_fragment(term)  
    return if !term
    if term.is_a?(String)
      term = Term.find_by_text(term)
    end
    return if !term
    expire_term_page(term)
#    expire_action({:controller=>"term",:action=>"*#{term.id}"})
    expire_action({:controller=>"term",:action=>term.url_text})
    term.future_matches.each{|match|
      expire_action({:controller=>"calendar_match",:action=>"#{match.id}"})
    }
    term.users.each{|user|
      logger.info("expire_user_page")
      expire_user_page(user)
      # also expire user's calendar
      }
    # expire L2 band page cache (tracker section)
    expire_action({:controller=>"bands",:action=>"tracker_section",:id=>term.url_text})
  end
  
  def use_full_width_footer
    @full_width_footer=true
  end
  
  def find_user
    @username=request.raw_post
    @username= @username.chomp.split("&_=").first if @username
    if @username and !@username.empty?
      @users = User.find_by_sql("select * from users where name like '#{@username}%' limit 5")
    end
    render(:layout =>false)
  end  

  protected  

  def log_error(exception) 
    super(exception)
    begin
      ExceptionMailer.deliver_snapshot(@metro_code,
        exception, 
        clean_backtrace(exception),
        @session.instance_variable_get("@data"), 
        @params, 
        @request.env) if ENV['RAILS_ENV']=='production'
    rescue => e
      logger.error(e)
    end
  end  
  
  def log_time(label)
    logger.info("#{label} => #{Time.now.to_f}")
  end
end