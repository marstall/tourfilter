class Action < ActiveRecord::Base

  establish_connection "shared_#{ENV['RAILS_ENV']}" 
  
  OBJECT_TYPE_TERM = "term"
  OBJECT_TYPE_USER = "user"
  OBJECT_TYPE_WEEKLY_NEWSLETTER = "weekly_newsletter"
  OBJECT_TYPE_MONTHLY_NEWSLETTER = "monthly_newsletter"

  ACTION_TYPE_REGISTERED = "registered"
  ACTION_TYPE_ADDED = "added"
  ACTION_TYPE_REMOVED = "removed"
  ACTION_TYPE_SENT = "sent"
  

  def self.user_registered(user,referer_domain=nil,referer_path=nil)
    description=nil
    description=user.terms_as_text.split("\n").size if (user.terms_as_text)
    self.create(user.metro_code,user,ACTION_TYPE_REGISTERED,user.registration_code,nil,nil,description,nil,user.referer_domain,user.referer_path)
  end

  def self.user_added_term(metro_code,user,term,note=nil,note_entity=nil)
    self.create(metro_code,user,ACTION_TYPE_ADDED,OBJECT_TYPE_TERM,term.id,term.text,note,note_entity)
  end

  def self.user_followed_user(metro_code,user1,user2)
    self.create(metro_code,user1,ACTION_TYPE_ADDED,OBJECT_TYPE_USER,user2.id,user2.name.downcase)
  end

  def self.user_unfollowed_user(metro_code,user1,user2)
    self.create(metro_code,user1,ACTION_TYPE_REMOVED,OBJECT_TYPE_USER,user2.id,user2.name.downcase)
  end
  
  def self.weekly_newsletter_sent(metro_code,user) 
    self.create(metro_code,user,ACTION_TYPE_SENT,OBJECT_TYPE_WEEKLY_NEWSLETTER,user.id,"sent weekly newsletter")
  end
  
  def self.monthly_newsletter_sent(metro_code,user) 
    self.create(metro_code,user,ACTION_TYPE_SENT,OBJECT_TYPE_MONTHLY_NEWSLETTER,user.id,"sent monthly newsletter")
  end
  
  def self.create(metro_code,user,action_type,object_type,id,description,note=nil,note_entity=nil,referer_domain=nil,referer_path=nil)
    action = Action.new
    action.username = user.name.downcase
    action.user_registered_on=user.registered_on
    action.user_id=user.id
    action.metro_code=metro_code
    action.object_id=id
    action.action=action_type
    action.object_type=object_type
    action.object_description=description
    action.note=note
    action.note_entity=note_entity
    action.referer_domain=referer_domain
    action.referer_path=referer_path
    action.save
  end
end
