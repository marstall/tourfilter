# Filters added to this controller will be run for all controllers in the application.
# Likewise, all the methods added will be available for all controllers.
require 'rubygems'
require 'fileutils'
require 'digest/md5'
require 'geoip'
#require 'net/https'

@@geoip = nil

class ApplicationController < ActionController::Base

  include CalendarModule
  include RefererModule
  
#  caches_page :bands_wrapper
  HTML_REGEXP=/[<>;]|(update|delete|insert)\s/
  SALT="BRUN TAXMAN"
#  before_filter :perform_hostname_corrections
  before_filter :signup_intercept, :only=>[:homepage]
#  before_filter :convert_to_new_url_structure_2
  before_filter :initialize_metro, :except=>[:locate,:geolocate,:redirect,:related_terms]
  before_filter :connect_to_the_correct_database
  before_filter :initialize_user, :except => :login
  before_filter :mark_time
  before_filter :ensure_www
  before_filter :set_tracking_cookie,:except => :track_click
  before_filter :set_referer_cookie,:except => :track_click    
  before_filter :set_page_cache_directory
  before_filter :setup_options
  after_filter :track_referer
#  after_filter :log_page_view, :except => :track_click
  
#  def fragment_cache_key(name)
#    puts "name: #{name.inspect}"
#    name.is_a?(Hash) ? url_for(name).split("://").last : name
#  end


  def geoip
    @@geoip||=GeoIP.new("#{RAILS_ROOT}/maxmind/GeoLiteCity.dat")
  end

  def track_referer
    log_referer(request,cookies)
  end

  def setup_options
    @options=cookies 
    
  end

  def set_page_cache_directory
    page_cache_directory="#{page_cache_directory}/#{metro_code}/CRANK/"
  end

  @show_venues=false
  @@metro_map=nil
  
  def prepare_external_click_hash
    @external_click_hash=Hash.new('link_source'=>"web")
  end
  
  def redirect_to(options)
    if options.is_a? Hash
      options[:controller]="#{@metro_code}/#{options[:controller]}" if options[:controller]
    elsif options==:homepage
      options="/"
    elsif options.is_a? String and options =~/^\//
      options="/#{@metro_code}#{options}" unless options=~/^\/#{metro_code}/
    end
    super(options)
  end

  def redirect_to(options,*parameters_for_method_reference)
    if options.is_a? Hash
      options[:controller]="#{@metro_code}/#{options[:controller]}" if options[:controller]
    elsif options==:homepage
      options="/"
    elsif options.is_a? String and options =~/^\//
      options="/#{@metro_code}#{options}" unless options=~/^\/#{metro_code}/
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

  @@uk_metros = nil
  @@us_metros = nil
  @@international_metros = nil
  def make_metro_map
#    logger.info("make_metro_map")
    if @@uk_metros
      @uk_metros=@@uk_metros
    else
      @uk_metros = Metro.find_all_by_country_code("uk",:order=>"name")
    end
    if @@us_metros
      @us_metros=@@us_metros
    else
      @us_metros = Metro.find_all_by_country_code("us",:order=>"name")
    end
    if @@international_metros
      @international_metros=@@international_metros
    else
      @international_metros = Metro.find_by_sql("select * from metros where country_code<>'us' and country_code<>'uk' order by name")
    end
    map=Hash.new
    @uk_metros.each{|metro|
      map[metro.code]=metro
    }
    @us_metros.each{|metro|
      map[metro.code]=metro
    }
    @international_metros.each{|metro|
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
      @metro_code||="shared"
      database_code=@metro_code
      if database_code=="facebook" or database_code=="search"
        database_code="shared"
      end
      logger.info("database_code: #{database_code}")
      ActiveRecord::Base.establish_connection(
        :adapter  => "mysql",
        :host     => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['host'],
        :username => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['username'],
        :password => ActiveRecord::Base.configurations[ENV['RAILS_ENV']]['password'],
        :database => "tourfilter_#{database_code}"
        )
    rescue => e
      log_error(e)
      puts "error!"
    end
  end
  
  def related_terms
    num=params[:num].to_i||num_related
    num=7 if num==0
    terms_as_text=request.raw_post        
    term_text_array=Array.new
#    line_end = true if terms_as_text~=/\n/
    terms_as_text.chomp.split(/([\n,]|%0A|%0D|\&\_\=)+/).each { |term_text|
      term_text.strip!
      next if term_text=~ /&_=/
      next if term_text== "%0A"
      next if term_text.size<3
      term_text.gsub!("%20"," ")
      term_text_array<<term_text
      logger.info("+++"+term_text)
    } if terms_as_text
    @term_texts=term_text_array
    if term_text_array.empty?
      @popular_terms = RelatedTerm.random_set(500,6,term_text_array)
    end
    render(:layout=>false)
  end

  def _related_terms(ren=true,num_related=7)
    num=params[:num].to_i||num_related
    num=7 if num==0
      terms_as_text=request.raw_post        
      term_text_array=Array.new
      terms_as_text.chomp.split(/([\n,]|%0A)+/).each { |term_text|
        term_text.strip!
        next if term_text=~ /&_=/
        next if term_text.size<3
        term_text.gsub!("%20"," ")
        term_text_array<<term_text
      } if terms_as_text
    num+=(term_text_array.size*3) if term_text_array
    term_text_array+=@youser.terms if @youser
    logger.info("+++ num:"+num.to_s)
    setup_related_terms(term_text_array,num)  
    @related_terms||=[]
    if (not @youser and @related_terms.size<=0)
      random_related_terms=RelatedTerm.random_set(500,6,term_text_array)
      @related_terms=random_related_terms+@related_terms
    end
    if params[:random]
      @related_terms=RelatedTerm.random_set(500,num,term_text_array)
    end
    if @related_terms.length>20
      max_same=3
    else
      max_same=5
    end
    rts = @related_terms
    @related_terms=[]
    same_index=0
    last_term_text=""
    logger.info("+++#{@related_terms.length}")
    rts.each{|related_term|
      logger.info("+++"+related_term.term_text+":"+last_term_text+":"+same_index.to_s)
      if related_term.term_text==last_term_text
        same_index+=1 
      else
        same_index=0
      end
      last_term_text=related_term.term_text
      @related_terms<<related_term if same_index<max_same or related_term.default?
    }
    render(:layout=>false) if ren 
  end
  
  def setup_related_terms(terms,num)
    return if not terms or terms.empty?
      terms_hash=Hash.new
      terms.each{|term|
        if terms.is_a? String
          terms_hash[term]=true
        else
          terms_hash[term.id]=true
        end
      }
      _related_terms=Term.find_related_terms(terms)
      @related_terms=Array.new
      _related_terms.each{|related_term|
        break if @related_terms.length>50
        @related_terms<<related_term if not terms_hash[related_term.related_term_text] and not terms_hash[related_term.related_term_id]
        break if @related_terms.size>num
      }
      return @related_terms
  end

  def homepage_signup
    _metro_code = get_cookie("metro_code")
    if _metro_code && _metro_code.size>0
      redirect_to "/#{get_cookie('metro_code')}"
      return false
    end
    @not_in_a_city=true
    @header_title='Spam-free concert alerts.'
    render('edit/homepage_signup',:layout=>false)
  end

  def signup_intercept
    puts "signup_intercept"
    if not params[:metro_code]
      #render_component(:controller=>'edit',:action=>'homepage_signup') 
      homepage_signup
      return false
    else
      return true
    end
  end

  def set_metro_code(metro_code)
    return if metro_code=='search'
    set_cookie("metro_code",metro_code)
    @metro_code=metro_code
  end

  def initialize_metro
    SETTINGS['date_type']='us'
    @metro_map = Hash.new
    @metro_map=make_metro_map
    request.host =~ /(\w+)\.(tourfilter\.(?:org|com|net|local))/
    @domain_stub=$2
    subdomain=$1
    url_metro_code=params[:metro_code]
    if not @metro_map[params[:metro_code]]
      url_metro_code=subdomain
    end
    logger.info("params[:metro_code]: #{params[:metro_code]}")
    logger.info("subdomain: #{subdomain}")
    logger.info("url_metro_code: #{url_metro_code}")
    if /^\/search/=~request.request_uri
      @not_in_a_city=true
      set_metro_code("search")
      @metro_name="all-cities search"
      return
    end
    if /^\/facebook/=~request.request_uri
      @not_in_a_city=true
      set_metro_code("facebook")
      @metro_name="facebook"
      return
    end

    if @metro_map[url_metro_code] and not @metro_map[url_metro_code].name.empty?
      @metro = @metro_map[url_metro_code].name
#      logger.info("@metro: #{@metro}")
      @num_places = @metro_map[url_metro_code].num_places 
#      logger.info("num_places: #{@num_places}")
      @metro_active = @metro_map[url_metro_code].active?
      set_metro_code(url_metro_code)
#      logger.info("@metro_code: #{@metro_code}")
    else
#      logger.info("request.host: #{request.host}")
      if !@metro_code
        set_metro_code(get_cookie("metro_code"))
        if @metro_code # if it was in the cookie
          redirect_to "/#{@metro_code}#{request.path}"
          return false
        end
      end
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
#     redirect_to "/boston" if request.path and request.path.strip=="/"
	   return true

# get the subdomain and the path_code
    request.host =~ /(\w+)\.(tourfilter\.(?:org|com|net|local))/
    domain_stub=$2
    subdomain=$1
    path = request.path
   original_path=path 
#	 logger.info("request.request_uri in convert_1: #{request.request_uri}")
#    logger.info("request.path in convert_1: #{request.path}")
#    puts("subdomain in convert_1: #{subdomain}")
    path_code = (request.path.scan(/[^\/]+/)||[""]).first
    metro_map = make_metro_map
    metro_map["facebook"]=true
    metro_map["search"]=true
    metro_map["b0ston"]=true
#    logger.info("subdomain in convert_1: #{subdomain}")
#    logger.info("path_code in convert_1: #{path_code}")
#    puts("subdomain in convert_1: #{subdomain}")
#    puts("path_code in convert_1: #{path_code}")
    original_path="/#{original_path}" unless original_path=~/^\// 
    # e.g. if the url is "www" and the path doesn't start with "/boston" or "/newyork" etc.
    if not metro_map[subdomain] and not metro_map[path_code]
#      logger.info "http://#{domain}/boston#{original_path}"
#      puts "http://#{domain}/b0ston#{original_path}"
      redirect_to("http://#{domain}/b0ston#{original_path}",false)
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
    path_code = (request.path.scan(/[^\/]+/)||[""]).first
    metro_map = make_metro_map
    metro_map["facebook"]=true
    metro_map["search"]=true
#    logger.info("subdomain in convert_2: #{subdomain}")
#    logger.info("path_code in convert_2: #{path_code}")
#    puts("subdomain in convert_2: #{subdomain}")
#    puts("path_code in convert_2: #{path_code}")
    if subdomain!="www" and subdomain!="beta"
      if request.path=~/^\/facebook/ or request.path=~/^\/search/
        _url = "http://#{domain}#{request.path}"
        redirect_to(_url,false)
      else 
        _url = "http://#{domain}"
        _url += "/#{subdomain}" if subdomain and not subdomain.strip.empty?
        _url += "#{request.path}"
#        logger.info "redirecting to #{_url}"
#        logger.info "domain: #{domain}"
#        logger.info "subdomain: #{subdomain}"
#        logger.info "request.path: #{request.path}"
        redirect_to(_url)
      end
      return false
    end
    return true
  end

  def perform_hostname_corrections
#    redirect_to "/boston" if request.path and request.path.strip=="/"
  end

  def ensure_www
    if request.host=='tourfilter.com'
      redirect_to "http://www.tourfilter.com#{request.path}"
      return false     
    end
    return true if request.host=~/antiplex|amazon|localhost|tourfilter\.(com|local)|^192.168/
    redirect_to "http://www.tourfilter.com#{request.path}"
    return false     
  end
 

  def must_have_manage_match_privs
    return false if not must_be_known_user
    if @youser.privs.nil?||(@youser.privs !~ /admin|manage_matches/ )
      flash[:error]="You don't have permission to access that page!"
      redirect_to '/'
      return false 
    end
    return true
  end

  def is_admin?
    session[:is_admin]
  end

  def must_be_admin
    return false if not must_be_known_user
    return true if session[:is_admin]
    if !@youser.privs||@youser.privs!="admin"
      flash[:error]="You don't have permission to access that page!"
      redirect_to '/'
      return false 
    end
    return true
  end

  def must_be_known_user_no_message
    if !@youser_known
      redirect_to login_url
      return false
    end
    return true
  end
  

  def url(_url)
    return unless _url =~ /^\//
    # add metro_code to url
    return _url if _url=~/^\/#{metro_code}/
    "/#{metro_code}#{_url}"
  end
  

  def must_be_known_user(msg=nil)
    msg||="You must be logged in to do that!"
    return true if session[:is_admin]
    if !@youser_known
      flash[:error]=msg
      redirect_to login_url
      return false
    end
    return true
  end
  
  def login_url(redirect_url=nil)
    redirect_url||=request.path
    "/login?redirect_url=#{redirect_url}"
  end

  def signup_url(params)
    redirect_url=params[:redirect_url]||"/"
    "/signup?redirect_url=#{redirect_url}"
  end

  def basic_signup_url(redirect_url=nil)
    redirect_url||=request.path
    "/basic_signup?redirect_url=#{redirect_url}"
  end
  
  def mark_time
    @before = Time.new
    return true
  end
  
  def start_timer
    @timer=Time.new
  end
  
  def log_interval(label='')
    interval = Time.new-@timer
    logger.info("+++ TIME #{label}: #{interval}")
  end
  
  def get_cookie(name)
    cookies[name]
  end
  
  def set_cookie(name,value,path="/",expires=10.years.from_now)
    cookies[name] = {
                          :value => value,
                          :expires => expires,
                          :path => path
                    }
  end
  
  def set_tracking_cookie
    # generate permanent tracking cookie based on session_id
    cookies[:psid] = {
                          :value => String(session.id),
                          :expires => 10.years.from_now,
                          :path => "/#{@metro_code}"
                        }     if not cookies[:psid]
    return true
  end
  
  def set_referer_cookie
    # extract referer_domain and put that in the cookie if the user is not logged in
    referer = request.env['HTTP_REFERER']
    return true if not referer or referer.empty?
#    logger.info("SETTING REFERER COOKIE TO #{referer}")
    cookies[:ref] = {
                          :value => String(referer),
                          :expires => 10.years.from_now,
                          :domain => ".tourfilter.com",
                          :path => "/"
                      } if referer !~ /tourfilter\.(com|local)/
#                      } if referer !~ /^http\:\/\/\w{1,32}\.tourfilter\.(com|local)/
    return true
  end

  def bands_wrapper
    render_component(:controller=>"bands",:action=>"bands",:id=>params[:id],:params=>{:metro_code=>@metro_code})
  end


  def log_external_click(ec,referer_id=nil)
#    return if ENV['RAILS_ENV']=='development'
    if @youser
      ec.youser_id = @youser.id 
    else
      ec.youser_id = -1
    end
    ec.ip_address = request.remote_ip
    if ec.url==nil
      ec.url = request.path
    else
        ec.url =~ /((\w+)?\.(\w+)?\.(edu|com|org|fr|net|uk|co.uk|at|local)|localhost:3000)/
        if $&
          ec.domain=$&
#          ec.url=$'
        else
          ec.url=ec.url
        end
    end
    ec.referer=request.env['HTTP_REFERER'] #if not referer
    # use 'original' referer in place of local referers ...
    referer_domain=nil
    if ec.referer
      #extract domain from referer
      ec.referer =~ /((\w+)?\.(\w+)?\.(edu|com|org|fr|net|uk|local)|localhost:3000)/
      if $&
        ec.referer_domain=$&
#        ec.referer=$'
      else
        ec.referer=referer
      end
    end
    original_referer=cookies[:ref]
    if original_referer
      #extract domain from referer
      original_referer =~ /((\w+)?\.(\w+)?\.(edu|com|org|fr|net|uk|local)|localhost:3000)/
      if $&
        ec.original_referer_domain=$&
        ec.original_referer_path=$'
      else
        ec.original_referer_path=nil
      end
    end
    ec.session_id = session.session_id
    ec.perm_session_id = cookies[:psid]
    ec.user_agent = request.env['HTTP_USER_AGENT']
#    ec.referer = referer
#    ec.referer_domain=referer_domain
    @before||Time.new
    ec.time_to_render = Time.new-(@before||Time.new)
    ec.metro_code=@metro_code
    ec.link_source||='web'
    referer_id||=cookies[:referer_id]
    ec.referer_id=
    ec.save
    referer = Referer.find(referer_id) rescue nil
    if referer
      referer.external_click_id=ec.id
      referer.external_click_domain=ec.domain
      referer.save
    end
    # associate with search_click
    return true
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
    session_user_id = session[:"#{@metro_code}_user_id"]
    if !session_user_id.nil?
      @youser_known = true
      @youser_logged_in = true
      @youser_id = session_user_id
    end
    if cookie_user_id and id_hash
      session[:"#{@metro_code}_user_id"]=cookie_user_id
      compare_hash = generate_cookie_hash(cookie_user_id)
      if id_hash!=compare_hash
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
        @youser.metro_code=@metro_code
        
        record_visit
      end
    rescue      
      logout
      return true
    end
    if @youser
      logger.info("@youser: #{@youser.name}") 
    else
      logger.info("not logged in") 
    end
    return true
  end
  
  def login
    login_with_name_password(params[:name],params[:password])
  end
  
  def login_user (user,redirect=true)
    name=user.name
    name=user.email_address if user.registration_type=="basic"

    login_with_name_password(name,user.password,redirect)
  end
  
  def login_with_name_password(name,password,redirect=true)
    if request.post?
      # HACK
      if name=~/\@/
        @youser = User.find_by_email_address_and_password(name,password) 
      else
        @youser= User.find_by_name_and_password(name,password)
      end
      if @youser.nil?
        @youser= User.find_by_email_address_and_password(name,password)
      end
      if @youser.nil?
        url = "/#{@metro_code}/lost_password"
        flash[:notice] = "Unknown username and/or password. Did you <a href='#{url}'>forget your password?</a>"
        redirect_to request.env['HTTP_REFERER'] # just refresh the page
        return
      else
        @youser.last_logged_in_on=DateTime.now
        @youser.metro_code=@metro_code
        logger.info( "+++ #{metro_code}: #{@youser.metro_code}")
        @youser.save 
        cookies['calndar_view']='add_SP_bands'
        
#       domain="#{@metro_code}.#{@domain_stub}" 
#       domain=@domain_stub if @youser.privs=='admin' 
        cookies[:calendar_view] = {
                      :value => "my",
                      :expires => 360.days.from_now,
                      :path => "/#{@metro_code}"
                    }
        session[:"#{@metro_code}_user_id"] = @youser.id
        session[:is_admin] = true if @youser.privs=~/admin/ # for all cities, note!!
        cookies[:"#{@metro_code}_user_id"] = {
                              :value => String(@youser.id),
#                              :domain => domain,
                              :expires => 360.days.from_now,
                              :path => "/#{@metro_code}"
                            }
        cookies['admin']='1'
        id_hash= generate_cookie_hash(@youser.id)
        cookies[:"#{@metro_code}_id_hash"] = {
                              :value => String(id_hash),
                              :expires => 360.days.from_now,
                              :path => "/#{@metro_code}"
                            }
        if @youser.privs=~/admin|manage_matches/
          cookies[:"manage_matches"] = {
                              :value => 'true',
                              :expires => 360.days.from_now,
                              :path => "/#{@metro_code}"
                            }
        end
      end
#      if request.env['HTTP_REFERER'] =~ /edit/
#        redirect_to(:controller => "home")
#      else
#        flash[:notice] = 'Logged in!' unless flash[:notice]
#        redirect_to request.env['HTTP_REFERER'] if redirect # just refresh the page
       redirect_url=params[:redirect_url]||"/"
       redirect_to redirect_url if redirect
#      end
    end
  end
  
  def logout
    cookies['calndar_view']='full_SP_calendar'
    session[:"#{@metro_code}_user_id"] = nil
    session[:is_admin]= nil
    cookies[:calendar_view] = {
                          :value => "",
                          :expires => 360.days.from_now,
                          :path => "/#{@metro_code}"
                        }
    cookies[:"#{@metro_code}_user_id"] = {
                          :value => "",
                          :expires => 360.days.from_now,
                          :path => "/#{@metro_code}"
                        }
    cookies[:"#{@metro_code}_id_hash"] = {
                          :value => "",
                          :expires => 360.days.from_now,
                          :path => "/#{@metro_code}"
                        }
    cookies[:"manage_matches"] = {
                        :value => '',
                        :expires => 360.days.from_now,
                        :path => "/#{@metro_code}"
                      }
#    flash[:notice] = 'Logged out!'
    redirect_to "/"
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

  def expire_action(options)
    super(options)
    if options.is_a? Hash
      options[:controller]="#{@metro_code}/#{options[:controller]}" if options[:controller]
    elsif options.is_a? String and options =~/^\//
      options="/#{@metro_code}#{options}" 
    end
    logger.info "+++ expiring #{options.inspect}"
    super(options)
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
    expire_action({:controller=>"nightly",:action=>"calendar_#{user.id}"})
    expire_action({:controller=>"nightly",:action=>"band_list_#{user.name}"})
  end
  
  def expire_nightly_caches
    manually_expire_cache_directory("nightly")
  end

  def manually_expire_cache_directory(directory_name)
    return if directory_name=~/\.\./ # guard against deletion above the cache directory!
    to_delete= "#{RAILS_ROOT}/cache/www.tourfilter.com/#{@metro_code}/#{directory_name}"
    FileUtils.rm_rf(to_delete,{:verbose=>true}) 
    to_delete= "#{RAILS_ROOT}/cache/www.tourfilter.local.3000/#{@metro_code}/#{directory_name}"
    FileUtils.rm_rf(to_delete,{:verbose=>true}) 
    to_delete= "#{RAILS_ROOT}/cache/www.tourfilter.com.3000/#{@metro_code}/#{directory_name}"
    FileUtils.rm_rf(to_delete,{:verbose=>true}) 
  end

  def expire_page(hash)
    super(hash)
    controller=hash[:controller]
    controller="#{controller}/" unless controller=~/\/$/
    hash[:controller]="#{@metro_code}/#{controller}"
    super(hash)
  end

  # expire_term_page - invalidate the l1-cache for this term ... (eg "/bands/Sparklehorse")
  def expire_term_page(term)
    return if !term
    puts("+++ term.to_s: #{term.inspect}")
    expire_page(:controller=>"bands",:action=>term.url_text)
    expire_page(:controller=>"bands",:action=>term.url_text_old)
  end

  def expire_public_recommendation_caches
    expire_recommendation_caches
    render(:inline => 'public recommendation caches expired!')
  end
  
  def expire_public_calendars_caches(do_render=true)
    expire_action(:controller=>"edit",:action=>"terms_by_place")
    expire_action(:controller=>"calendar",:action=>"index")
    expire_action(:controller=>"edit",:action=>"homepage_calendar")
    0.upto(90) {|i| expire_action(:controller=>"edit",:action=>"homepage2_calendar_#{i}")}
    expire_action(:controller=>"edit",:action=>"place_dropdown")
    expire_action(:controller=>"ical",:action=>"ical")
    expire_page(:controller => "calendar", :action=>"index")
    expire_page(:controller => "edit", :action=>"index")
    expire_page(:controller => "/", :action=>"homepage")
    render(:inline => 'public calendars caches and homepage expired!') if do_render
  end

  def expire_recent_users_caches
#    expire_fragment(%r{/edit/recent_users/.*})
  end

  def expire_recommendation_caches(recommendation=nil)
#    expire_fragment(%r{/home/recommendations})
    expire_term_fragment(recommendation.match.term) if recommendation
  end
  
  # expire_term_fragment - invalidate the l2 bandlist term fragment, the l2 calendar term fragment and all l1-user and l1-band page caches that contain it.
  # also expire the me page page-level cache.
  def expire_term_fragment(term)  
    return # defunct now
    term = Term.find_by_text(term)  if term.is_a?(String)
    return if !term
    expire_term_page(term)
    expire_action({:controller=>"bands",:action=>"#{term.text}"})
    expire_action({:controller=>"term",:action=>term.url_text})
    term.future_matches.each{|match|
      expire_action({:controller=>"calendar_match",:action=>"#{match.id}"})
    }
    term.future_matches.each{|match|
      expire_action({:controller=>"image_calendar_match",:action=>"#{match.id}"})
    }
    term.users.each{|user|
      logger.info("expire_user_page")
      expire_user_page(user)
      # also expire user's calendar
      }
    # expire L2 band page cache (tracker section)
    expire_action({:controller=>"bands",:action=>"tracker_section",:id=>term.url_text})
    expire_public_calendars_caches(false)
#    expire_action({:controller=>"bands",:action=>"full_page",:id=>term.url_text})
  end
  

  def invalidate_caches_for_match_comments(match)
    match=match.match if match.is_a? Comment
    expire_action({:controller=>"bands",:action=>"match_comments",:id=>match.id})
    expire_action({:controller=>"bands",:action=>"all_match_comments",:id=>match.id})
    expire_action({:controller=>"bands",:action=>"tracker_section",:id=>match.id})
    if match.term 
      expire_term_page(match.term) 
      expire_term_fragment(match.term)
    end
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

  def rescue_action_in_public(e)
    log_error(e)
    super(e)
  end

  def log_error(exception) 
    super(exception)
    return
    begin
      if exception.message !~/No route matches/
        ExceptionMailer.deliver_snapshot(@metro_code,
          exception, 
          clean_backtrace(exception),
          @session.instance_variable_get("@data"), 
          @params, 
          request.env)# if ENV['RAILS_ENV']=='production'
      end
    rescue => e
      logger.error(e)
    end
  end  
  
  protected  
  
  def log_time(label)
    logger.info("#{label} => #{Time.now.to_f}")
  end
end
