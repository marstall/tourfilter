class TestMailer < ActionMailer::Base

  def test(to, subject)
    @subject    = subject
    @recipients = to
    @from       = 'info@tourfilter.com'
    @sent_on    = Time.now
    @headers    = {}
  end
end
