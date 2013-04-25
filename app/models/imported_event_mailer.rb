class ImportedEventMailer < ActionMailer::Base

  def imported_event_edited(imported_event, metro_code, user, action, sent_at = Time.now)
    @subject    = "#{user.name} #{action.strip}: #{imported_event.body} (#{metro_code} #{imported_event.tags})"
    @body["imported_event"]       = imported_event
    @body["user"]       = user
    @body["metro_code"]       = metro_code
    @body["action"]       = action
    @bcc=['chris@tourfilter.com']
    @recipients = 'chris@psychoastronomy.org'
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def imported_event_reflyered(imported_event, metro_code, user, sent_at = Time.now)
    @subject    = "#{user.name} reflyered one of your flyers!"
    @body["imported_event"]       = imported_event
    @body["user"]       = user
    @body["metro_code"]       = metro_code
    @recipients = imported_event.user.email_address
    @from       = 'Tourfilter <info@tourfilter.com>'
    @sent_on    = sent_at
    @headers    = {}
  end

  
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
