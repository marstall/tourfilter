class SecondaryTicketSeller < ActiveRecord::Base
   establish_connection "shared" unless $mode=="import_daemon"
end
