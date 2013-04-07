class MovieEditedMailer < ActionMailer::Base

  def movie_edited(movie, action="video changed", sent_at = Time.now)
    @subject    = "movie edited: #{movie.title}"
    @body["movie"]       = movie
    @recipients = 'chris@psychoastronomy.org'
    @from       = 'info@tourfilter.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
