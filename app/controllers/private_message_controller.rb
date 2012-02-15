class PrivateMessageController < ApplicationController  

def send_message
  return if not must_be_known_user
  use_full_width_footer
  id=params[:id]
  @user=User.find_by_name(id) 
  @user=User.find(id) if not @user
  if @user
    @user_name = @user.name
    render :action => "send_message"
  else
    render(:inline=>"Unknown user!")
    return
  end
end


def handler
  message = params[:message]
  if message==nil or message.size==0
    error = "You must include a message"
  end
  if message and message.size>65536
    error = "Your message cannot be larger than 64K"
  end
  if error
    render(:inline=>error)
    return
  end
  begin
    @user=User.find_by_name(params[:user_name])
    PrivateMessageMailer::deliver_private_message(self,@youser,@user,message)
    Event.private_message_sent(@youser,@user,message)
#  rescue => e
#    render(:inline=>"There was an error ! Please try sending your message at a later date.<br>(#{e.to_s})")
#    return
  end
  render(:inline=>"<script>alert('Your message to #{@user.name} was successfully sent!');location.href='/#{metro_code}';</script>",:layout=>false)
end

end
