class ImportedEventFlaggedMailer < ActionMailer::Base

  def imported_event_flagged(imported_event, metro_code, user, note, sent_at = Time.now)
    @subject    = "sorry, but that flyer doesn't fit our guidelines."
    @body["imported_event"]       = imported_event
    @body["user"]       = user
    @body["metro_code"]       = metro_code
    @recipients = user.email_address
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
