#begin
#  require 'rubygems'
#  require_gem 'redcloth', ">= 3.0.4"
#rescue LoadError
#  require 'redcloth'
#end

class SettingsController < ApplicationController  

include QuickAuthModule


def unsubscribe
  @full_width_footer=true
  if not quick_authenticate(params)
    render(:inline=>"error. you were not unsubscribed.")
    return
  end
  @user=User.find(params[:id])
  @user.wants_weekly_newsletter='false'
  @user.wants_newsletter='false'
  @user.save_with_validation(false)
  @user = User.find(params[:id])
  render(:action=>'unsub')
end  

def settings_popup
  return if not must_be_known_user
  render(:action => "settings_popup",:layout=>false)
end

def settings
  return if not must_be_known_user
  #use_full_width_footer
  @page_title='settings'
  render(:action => "settings")
end

def index
  settings
end


def check_name
  name = request.raw_post
  return if name.length<4
  name=name.split("&_=").first    
  user = User.find_by_name(name)
  if user and user.id!=@youser.id
    render(:inline =>"<span style='color:red'>taken</span>")
  else
    render(:inline =>"<span style='color:green'>available</span>")
  end
end

def handler
  logger.info("button: #{params[:button]}")
  if params[:button]=~/Done/
    flash[:notice]="Registration complete!"
    render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
    return
  end
  if params[:youser][:about]=~HTML_REGEXP
    @youser.errors.add "about " 
  else
    @youser.update_attributes(params[:youser])
    @youser.registration_type="normal" and @youser.save if (@youser.name!="anon" and @youser.name!="none")
  end
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

def about_preview
  @about=request.raw_post
  @about = @about.gsub(/<([^>]+)>/," ") if @about # get rid of all html
  #r = RedCloth.new about
  #render(:inline => r.to_html)
  render(:layout =>false)
end

end
