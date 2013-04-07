class ImportedEventUnflaggedMailer < ActionMailer::Base

  def imported_event_unflagged(imported_event, metro_code, user, sent_at = Time.now)
    @subject    = "flyer unflagged!"
    @body["imported_event"]       = imported_event
    @body["user"]       = user
    @body["metro_code"]       = metro_code
    @recipients = user.email_address
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
