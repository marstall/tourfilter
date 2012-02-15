class TicketOfferArchive < ActiveRecord::Base
   unless $mode=="import_daemon"
     require "../config/environment.rb" if $mode=="daemon"
     establish_connection "shared" 
   end
end
