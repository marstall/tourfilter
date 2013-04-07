class Notifier 
  @@topics={"added_flyer"=>"arn:aws:sns:us-east-1:122872249816:tourfilter-topic"}

  def self.topics
    @@topics
  end

  def self.send_message(topic_arn,user,message,url)
    sns = AWS::SNS.new
    t = sns.topics[topic_arn]
    subject = "#{user.name} #{message}"
    puts "+++ #{subject}"
    t.publish("#{message}\r\n\r\n#{url}",:subject=>subject)
  end
end
