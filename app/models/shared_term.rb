class SharedTerm < ActiveRecord::Base

  establish_connection "shared_#{ENV['RAILS_ENV']}" 
  def url_text
    t =text.downcase # make it all lowercase
    t=t.gsub(/\s/,"_") #substitute underscores for spaces
  end
  
  def self.random_set(threshhold,num)
    SharedTerm.find_by_sql("select * from shared_terms where num_trackers>#{threshhold} order by rand() limit #{num};")
  end

end
