class Contact < ActiveRecord::Base
  establish_connection "shared_#{ENV['RAILS_ENV']}"
  belongs_to :user
  has_one :recommendation
  
end
