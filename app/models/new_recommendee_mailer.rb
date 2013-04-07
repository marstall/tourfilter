class NewRecommendeeMailer < ActionMailer::Base

  def new_recommendee(controller,rr, sent_at = Time.now)
    @subject    = "#{rr.recommendee.name} wants your recommendations"
    @body["rr"]       = rr
    @body["controller"]       = controller
    @recipients = rr.recommender.email_address
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
