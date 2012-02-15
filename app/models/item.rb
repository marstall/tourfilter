class Item < ActiveRecord::Base
   establish_connection "shared" unless $mode=="daemon"
   
   def url
     "#{detail_page_url}&tag=tourfilter-20"
   end
end
