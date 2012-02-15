class LostPasswordController < ApplicationController  


def lost_password
  use_full_width_footer
  render :action => "lost_password"
end

def index
  lost_password
end

def handler
  email_address=params[:email_address]
  if not email_address or email_address.empty?
    render (:inline => "You must enter an email address!")
    return
  end
  begin
    user = User.find_by_email_address(email_address)
  rescue
  end
  begin  
    email = LostPasswordMailer::deliver_lost_password(user) if user
  rescue
    render (:inline => "There was a technical glitch encountered sending your password. Sorry! Please try again a little later.")
    return
  end
  if !user
    render (:inline => "That email address is unrecognized!")
  else  
    render (:inline => "Your password has been mailed to #{email_address}!")
  end
end

end
