require "base64" 

class InvitationMailer < ActionMailer::Base

  def invitation(controller,invitation)
    @subject    = "#{invitation.from_user.name} has invited you to join Tourfilter #{controller.metro}"
    @body["ticket"]  = encode64(String(invitation.id*1024))
    logger.info("ticket: #{@ticket}")
    @body["invitation"]       = invitation
    @body["controller"]       = controller
    @recipients = invitation.email_address
    @from       = invitation.from_user.email_address
    @sent_on    = Time.now
    @headers    = {}
  end
end
