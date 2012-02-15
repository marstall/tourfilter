class FlagMatchMailer < ActionMailer::Base

  def flag_event(controller,match,user,event_description="",sent_at = Time.now)
    return if not match
    @subject    = "#{event_description}: #{match.term.text.downcase} at #{match.page.place.name.downcase} #{match.very_short_time_description}"
    @body["user"] = user
    @body["match"] = match
    @body["controller"] = controller
    @body["event_description"] = event_description
    @body["sent_on"] = sent_at
    @recipients = "flagging@tourfilter.com"
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end

  def flag_uto(controller,uto,user,sent_at = Time.now)
    return if not uto
    @subject    = "#{controller.metro_code}/#{user.name} flagged user ticket offer '#{uto.match_description}'"
    @body["user"] = user
    @body["uto"] = uto
    @body["controller"] = controller
    @body["sent_on"] = sent_at
    @recipients = "flagging@tourfilter.com"
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end

end
