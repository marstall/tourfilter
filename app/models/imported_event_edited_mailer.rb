class ImportedEventEditedMailer < ActionMailer::Base

  def imported_event_edited(imported_event, metro_code, user, action, sent_at = Time.now)
    @subject    = "#{user.name} #{action.strip}: #{imported_event.body} (#{metro_code} #{imported_event.tags})"
    @body["imported_event"]       = imported_event
    @body["user"]       = user
    @body["metro_code"]       = metro_code
    @body["action"]       = action
    @recipients = 'chris@psychoastronomy.org'
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
