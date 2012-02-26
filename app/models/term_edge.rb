class TermEdge < ActiveRecord::Base
  establish_connection "shared_#{ENV['RAILS_ENV']}"

end
