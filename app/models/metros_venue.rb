class MetrosVenue < ActiveRecord::Base

   establish_connection "shared" unless $mode=="import_daemon"

end
