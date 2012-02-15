require "search.rb"
require 'json'

#require "facebook_web_session"

FACEBOOK_API_KEY = 'f268ef64d9537e4b68057165cba207c6'
FACEBOOK_API_SECRET  = '9c0660a52301e79a35a3735dc61daa64'

FACEBOOK_TEST_API_KEY = '01dfb392c0553b3a3241a1229fc675e7'
FACEBOOK_TEST_API_SECRET = '67beb47f51de2b6eb01b4fa8783e5ba5'

require "facebook_rails_controller_extensions"

class FacebookController < ApplicationController  
#  caches_page :index
 
  def facebook_api_key
    if ENV['RAILS_ENV']=='development'
      return FACEBOOK_TEST_API_KEY 
    else
      return FACEBOOK_API_KEY
    end
  end

  def facebook_api_secret
    if ENV['RAILS_ENV']=='development'
      return FACEBOOK_TEST_API_SECRET
    else
      return FACEBOOK_API_SECRET
    end
  end

  @term_texts=nil
  
  def load_all_band_names
    shared_events=SharedEvent.find_by_sql("select distinct summary from shared_events")
    @term_texts=Hash.new
    shared_events.each{|shared_event|
        @term_texts[shared_event.summary]=true
      }
  end


  # additions to integrate Facebook into controllers
  include RFacebook::RailsControllerExtensions

  before_filter :require_facebook_login
  before_filter :require_facebook_install

  def facebook2
    @fb=fbsession
    @facebook_userid=fbsession.session_user_id    
    render(:inline=>"facebook userid #{@facebook_userid}")
  end

  def finish_facebook_login
    redirect_to "/facebook"
  # This is for IFRAME and external apps (not FBML apps)
  # It will be called upon successful login of a user.
  # Usually this means that you'll want to redirect to a "landing page" of sorts.
  end

  def refresh
    facebook(false)
    render(:layout=>false,:action=>"facebook_profile")
  end

  def facebook(render=true)
    load_all_band_names
#    authenticate and return unless fbsession
#    authenticate and return unless session[:facebook_session] and session[:facebook_session].session_uid
#    callback_without_redirect if params[:auth_token]
#    @facebook_session = session[:facebook_session]
#    @facebook_userid = session[:facebook_session].session_uid
     @facebook_session = fbsession
     @facebook_userid = @facebook_session.session_uid
     @tourfilter_username=nil
    begin
      @facebook_settings = FacebookSetting.find_by_facebook_userid(@facebook_userid)
      @tourfilter_username=@facebook_settings.tourfilter_username
    rescue
      @facebook_settings=nil
    end
    num=200   
    @metroo=Metro.new
    @query=params[:query]
    @metroo_code=params[:metroo][:code] if params[:metroo] and params[:metroo][:code]
     @metroo_code||=@facebook_settings.metro_code if @facebook_settings
    @metroo.code=@metroo_code||""
    _metro = Metro.find_by_code(@metroo_code) if @metroo_code and not @metroo_code.empty?
    @metroo_name=nil
    @metroo_name=_metro.name if _metro
    @metroo_name=nil if @metroo_name and @metroo_name.strip.empty?
    if @query and not @query.strip.empty?
      @query.gsub(/(\_|\+)/,' ').strip
      @shared_events = SharedEvent.search({:summary=>@query},num)
      puts @shared_events.inspect
      render(:layout=>false)
      return
    else
      @shared_events = SharedEvent.find_all_for_metro(@metroo_code,200) if @metroo_code
    end
    if @metroo_code
      @user_terms = get_users_music 
      @friend_terms = get_friends_music 
      @friend_terms = @friend_terms[0..50] # no more than 50 friend bands
      @my_shared_events = SharedEvent.search_with_multiple_terms(@user_terms,@metroo_code,50)
      @friends_shared_events = SharedEvent.search_with_multiple_terms(@friend_terms,@metroo_code,50)
    end

#    related_terms=find_related_terms(@user_terms)
#    related_terms2=Array.new
#    related_terms.each{|related_term| related_terms2<<related_term.downcase.gsub("'","")}
#    @related_shared_events = SharedEvent.search_with_multiple_terms(related_terms2,@metroo_code,num)

    update_local_settings
    update_facebook_profile
    render(:layout=>false) if render
end  

def stash_facebook_user_info(user)
    uid = (user/:uid).inner_html
    begin
      facebook_settings = FacebookSetting.find_by_facebook_userid(uid)
    rescue
    end
    if not facebook_settings
      facebook_settings=FacebookSetting.new
      facebook_settings.facebook_userid=uid
    end
    facebook_settings.friend_id=@facebook_userid unless @facebook_userid==uid
    facebook_settings.music=(user/:music).inner_html
    facebook_settings.name=(user/:name).inner_html
    facebook_settings.city=(user/:current_location/:city).inner_html
    facebook_settings.state=(user/:current_location/:state).inner_html
    facebook_settings.country=(user/:current_location/:country).inner_html
    facebook_settings.zip=(user/:current_location/:zip).inner_html
    facebook_settings.tv=(user/:tv).inner_html
    facebook_settings.has_added_app=(user/:has_added_app).inner_html
    facebook_settings.birthday=(user/:birthday).inner_html
    facebook_settings.save
end

def get_users_music(uids=nil)
  @term2uids=Hash.new
  uids||=@facebook_session.session_uid
  uids=[uids] if not uids.is_a? Array 

  xml = @facebook_session.users_getInfo({:uids => uids, :fields => ["music","name","current_location","tv","has_added_app","birthday"]})
  ret_terms=Array.new
#  puts xml
  (xml/:user).each do |user|
    stash_facebook_user_info(user)
    uid = (user/:uid).inner_html
    terms = (user/:music).inner_html.scan(/[^\r\n,]+/)
    terms.each{|term|
      next unless @term_texts[term] # skip if there is not an upcoming show for this band
      term=term.strip.downcase.gsub ("'","")
      @term2uids[term]="#{(@term2uids[term]||'')},#{uid}" unless @term2uids[term] and @term2uids[term][uid]
      #puts term
      ret_terms<<term
     }
  end
  ret_terms
end

def get_friends_music
  xml = @facebook_session.friends_get()
  terms=Array.new
  uids=Array.new
  (xml/:uid).each do |uid|
    uid=uid.inner_html
#    puts uid
    uids<<uid
  end
  get_users_music(uids[0..50]) # max 100 friends
end

# response: <?xml version="1.0" encoding="UTF-8"?>
# <profile_setfbml_response xsi:schemalocation="http://api.facebook.com/1.0/ http://api.facebook.com/1.0/facebook.xsd" 
# xmlns:xsi="http://www.w3.org/2001/XMLSchema-instance" xmlns="http://api.facebook.com/1.0/">1</profile_setfbml_response>


  def update_facebook_profile
    fbml=render_to_string(:action=> "facebook_profile",:layout=>false)
   # puts fbml
    logger.info fbml
    response = @facebook_session.profile_setFBML(:markup=>fbml)
    logger.info "response: #{response}"
  end
  
  def find_related_terms(terms)
    return Array.new if not terms or terms.empty?
      terms_hash=Hash.new
      terms.each{|term|
        if terms[0].is_a? String
          terms_hash[term]=true
        else
          terms_hash[term.id]=true
        end
      }
      _related_terms=Term.find_related_terms(terms)
      related_terms=Array.new
      _related_terms.each{|related_term|
        related_terms<<related_term.related_term_text if not terms_hash[related_term.related_term_text]
        break if related_terms.size>175
      }
      related_terms
  end
  
  
  def update_local_settings
    begin
      facebook_settings = FacebookSetting.find_by_facebook_userid(@facebook_userid)
    rescue
    end
    facebook_settings ||= FacebookSetting.new
    facebook_settings.facebook_userid=@facebook_userid
    facebook_settings.metro_code=@metroo_code
    facebook_settings.visited_canvas="true"
    facebook_settings.save
  end
  
  def index
    facebook
  end
  
  def test2
    render(:inline=>params.inspect)
  end
  
  def test
	authenticate
  end  

  def authenticate
    session[:facebook_session] = RFacebook::FacebookWebSession.new(FACEBOOK_API_KEY, FACEBOOK_API_SECRET)
    redirect_to session[:facebook_session].get_login_url
  end

  def callback
    begin
       session[:facebook_session].activate_with_token(params[:auth_token])
       redirect_to "/facebook"
    rescue RFacebook::FacebookSession::RemoteException => e
       flash[:error] = "An exception occurred while trying to authenticate with Facebook: #{e}"
    end
  end
end
