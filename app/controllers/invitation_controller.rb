class InvitationController < ApplicationController  

def invite
  return if not must_be_known_user
  use_full_width_footer
  render :action => "invite"
end

def welcome
  return if not must_be_known_user
  use_full_width_footer
  render :action => "welcome"
end


def index
  invite
end

def accept
    if not @youser
      cookies[:invitation_ticket] = {
                            :value => String(params[:id]),
                            :expires => 10.years.from_now,
                            :path => "/"
                          }
      flash[:notice]="Thanks for trying tourfilter! When you create an account, you will be connected with the person who invited you."
    end
    redirect_to '/'
end



def handler
  if params[:next]
    flash[:notice]="Last step! Fill out your mini-profile."
    render(:inline=>"<script>location.href='/#{@metro_code}/settings';</script>",:layout=>false)
    return
  end

  @errors = Array.new
  @successes = Array.new
  _email_addresses = params[:email_addresses]
  message = params[:message]
  
  if not _email_addresses or _email_addresses.strip.empty?
    @errors<<"You must enter at least one email address"
    render(:layout => false)
    return
  end
  good_addresses=Array.new
  bad_invitations = Array.new
  email_addresses=_email_addresses.split(/[,;\s\r\n]/)
  email_addresses.each{|email_address|
    email_address.strip!
    next if email_address.empty?
    begin
      invitation = Invitation.new
      invitation.email_address = email_address
      invitation.from_user_id = @youser.id
      invitation.message = message
      invitation.save!
    rescue
    end
    if not invitation.errors.empty?
      bad_invitations<<invitation
    else
      debugger
      good_addresses<<email_address
      InvitationMailer::deliver_invitation(self,invitation)
    end
  }
  bad_invitations.each{|invitation|
    @errors<<"'#{invitation.email_address}': #{invitation.errors.collect{|error| error}}"
    }
  good_addresses.each{|address|
    logger.info"successes<#{address}"
      @successes<<"An invitation was successfully sent to '#{address}'."
    }
    if not @errors.empty?
      render(:layout => false)
      return
    else
      flash[:notice]=@successes.collect{|success|"#{success}<br>"}
      referer = request.env['HTTP_REFERER']
      if referer=~/invite/
        render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
        return
      end
      if referer=~/welcome/
        flash[:notice]="#{flash[:notice]}\nLast step! Fill out your mini-profile."
        render(:inline=>"<script>location.href='/#{@metro_code}/settings';</script>",:layout=>false)
        return 
      end
    end
    render(:layout=>false)
    return false
end

end
