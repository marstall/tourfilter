class Item < ActiveRecord::Base
  establish_connection "shared_#{ENV['RAILS_ENV']}" unless $mode=="daemon"
   
   def url
     "#{detail_page_url}&tag=tourfilter-20"
   end
end
