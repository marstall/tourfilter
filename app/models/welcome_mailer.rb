class WelcomeMailer < ActionMailer::Base

  def welcome(controller,user,sent_at = Time.now)
    @subject    = 'Welcome to Reflyer!'
    @body["user"] = user
    @body["controller"] = controller
    @recipients = user.email_address
    @from       = 'info@reflyer.com'
    @sent_on    = sent_at
    @headers    = {}
  end
end
