class Invitation < ActiveRecord::Base
  
  validates_format_of :email_address,
                      :with => /^.+@.+\..+$/,
                      :message => " is invalid"
  validates_uniqueness_of :email_address,
            :message => " has already been invited"

  def from_user
    User.find(from_user_id)
  end        

  def to_user
    User.find(to_user_id)
  end        
end