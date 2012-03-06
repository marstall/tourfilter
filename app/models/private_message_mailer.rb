class PrivateMessageMailer < ActionMailer::Base
  def private_message(controller,youser,user,message)
    @subject    = "#{youser.name} has sent you a private message via tourfilter #{controller.metro.downcase}"
    @body["youser"]  = youser
    @body["user"]  = user
    @body["message"]  = message
    @body["controller"]       = controller
    @recipients = user.email_address
    @from       = "tourfilter private message <info@tourfilter.com>"
    @sent_on    = Time.now
    @headers    = {}
  end
end
