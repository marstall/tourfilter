class ExceptionMailer < ActionMailer::Base

  def snapshot(metro,exception,trace=nil,session=nil,params=nil,env=nil,sent_at = Time.now)
    content_type "text/html" 
    env||=Hash.new
    session||=Hash.new
    params||=Hash.new
    trace||=exception.backtrace
    metro||="unknown"
    @subject    = "#{metro}: #{exception.message.downcase}"
    @body["trace"]  = trace
    @body["exception"]  = exception
    @body["session"]    = session
    @body["params"]     = params
    @body["env"]        = env    
    @recipients = 'chris@psychoastronomy.org'
    @from       = "tourfilter exception <info@tourfilter.com>"
    @sent_on    = sent_at
    @headers    = {}
  end

end
