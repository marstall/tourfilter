class Event < ActiveRecord::Base
  belongs_to :user
  
  # Event.created(@youser,match,"email")
  
  attr_accessor :post_as

  def self.created(user,object,info=nil)
   Event.add(user,object,"create",info)
  end

  def self.updated(user,object,info=nil)
    Event.add(user,object,"update",info)
  end

  def self.deleted(user,object,info=nil)
    Event.add(user,object,"delete",info)
  end

  def self.viewed(user,object,info=nil)
    Event.add(user,object,"view",info)
  end

  def self.add(user,object,action,info=nil)
    return if object.nil?||action.nil?
    if object.is_a? String
      object_type=object
    else
      object_type=object.class
    end
    Event.add(user,object_type,object_id,action,info)
  end

  def self.add(user,object_type,object_id,action,info=nil)
    event = Event.new
    event.user_id=user.id if user
    event.action=action
    event.info=info
    event.object_type=object_type
    event.object_id=object_id
    event.save
  end
  
  def self.monthly_newsletter_sent(user)
      Event.add(user,"montly",nil,"create",user.email_address)
  end

  def self.weekly_newsletter_sent(user)
      Event.add(user,"weekly",nil,"create",user.email_address)
  end

  def self.match_email_created(match)
    match.term.users.each{|user|
      Event.add(user,"email",match.id,"create",user.email_address)
    }
  end
  
  def self.private_message_sent(youser,user,message)
    Event.add(youser,"private message",user.id,"create",String(message.size))
  end
  
end