class TicketOffer < ActiveRecord::Base
   unless $mode=="import_daemon"
     require "../config/environment.rb" if $mode=="daemon"
     establish_connection "shared_#{ENV['RAILS_ENV']}" 
   end

   belongs_to :imported_event

   def before_create
     ta = TicketOfferArchive.new
     ta.imported_event_id=imported_event_id
     ta.section=section
     ta.row=row
     ta.price=price
     ta.quantity=quantity
     ta.source=source
     begin
#       ta.save
     rescue
     end
   end
end
