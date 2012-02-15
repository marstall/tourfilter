class Venues < ActiveRecord::Base
   establish_connection "shared_#{RAILS_ENV}" 
end
