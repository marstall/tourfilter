class CorrectionMailer < ActionMailer::Base

  def correction(controller,match,sent_at = Time.now)
    return if not match
    @subject    = "date correction! #{match.term.text.downcase} at #{match.page.place.name.downcase} *#{match.very_short_time_description}*"
    @body["match"] = match
    @body["controller"] = controller
    @body["sent_on"] = sent_at
    @bcc=""
    match.term.users.each { |user| 
      @bcc+=(user.email_address+",")
    }
    @bcc+='tourfilter_bcc@psychoastronomy.org'
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
