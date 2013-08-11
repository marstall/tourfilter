class LostPasswordMailer < ActionMailer::Base

  def lost_password(user, sent_at = Time.now)
    @subject    = "Your Tourfilter password"
    @body["user"]       = user
    @recipients = user.email_address
    @from       = 'info@reflyer.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
