class ChangedSettingsMailer < ActionMailer::Base

  def changed_settings(user, sent_at = Time.now)
    @subject    = "Changed Settings"
    @body["user"]       = user
    @recipients = user.email_address
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
