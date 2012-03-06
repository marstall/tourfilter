class RecommendationMailer < ActionMailer::Base

  def recommendation(controller,recommendation,sent_at = Time.now)
    @subject    = "#{recommendation.user.name} recommends #{recommendation.match.term.text} at #{recommendation.match.page.place.name} #{recommendation.match.time_description}"
    @body["recommendation"]       = recommendation
    @body["controller"]       = controller
    @bcc        = 'tourfilter_recommendations@psychoastronomy.org,'
    recommendation.contacts.each { |contact| 
      @bcc+=(contact.email_address+",")
      }    
    recommendation.user.recommendees.each { |user| 
      @bcc+=(user.email_address+",")
      }
    @bcc=@bcc.chomp(",")    
    logger.info("bcc: #{bcc}")
    @from       = "Tourfilter User Recommendation <info@tourfilter.com>"
    @sent_on    = sent_at
    @headers    = {}
  end
end
