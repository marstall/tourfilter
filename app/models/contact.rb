class Contact < ActiveRecord::Base
  establish_connection "shared" #unless $mode=="import_daemon"
  belongs_to :user
  has_one :recommendation
  
end
