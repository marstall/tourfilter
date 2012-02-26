class SecondaryTicketSeller < ActiveRecord::Base
  establish_connection "shared_#{ENV['RAILS_ENV']}" unless $mode=="daemon"
end
