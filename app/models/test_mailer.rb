class TestMailer < ActionMailer::Base

  def test(to, subject)
    @subject    = subject
    @recipients = to
    @from       = 'chris@psychoastronomy.org'
    @sent_on    = Time.now
    @headers    = {}
  end
end
