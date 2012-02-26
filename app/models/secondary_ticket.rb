require "acts_as_indexable.rb" 

class SecondaryTicket < ActiveRecord::Base
  include ActsAsIndexable
  establish_connection "shared_#{ENV['RAILS_ENV']}" unless $mode=="daemon"
  
  def self.find_tickets(id)
    ret=Hash.new
    sts=SecondaryTicket.new.search(id.sub(/the/i,"").strip)
    sts.each{|st|
      ret[st.seller]=st.url
    } if sts
    ret
  end
  
  def cache_timeout
    60*60*4 # 4 hours
  end

end
