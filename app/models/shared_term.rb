
class SharedTerm < ActiveRecord::Base

  establish_connection "shared_#{ENV['RAILS_ENV']}" 
  def url_text
    t =text.downcase # make it all lowercase
    t=t.gsub(/\s/,"_") #substitute underscores for spaces
  end
  
  def self.random_set(threshhold,num)
    SharedTerm.find_by_sql("select * from shared_terms where num_trackers>#{threshhold} order by rand() limit #{num};")
  end
  
  def self.rand
    SharedTerm.find_by_sql("SELECT * FROM `shared_terms` ORDER BY RAND() LIMIT 0,1;")[0]
  end


  def SharedTerm.remove_punctuation(s)
    s.gsub(/[!-\/:-@]/,' ') # ascii punctuation range
  end
  
  def SharedTerm.find_terms_in(imported_event)
    body = imported_event.body.gsub("'","\'")
    id = imported_event.id
    processed_body = remove_punctuation(body)
    puts " checking against:"
#    puts processed_body
    puts "[ #{(body+processed_body).strip} ]"
    sql = <<-SQL
      select shared_terms.* from shared_terms,imported_events 
      where imported_events.id = #{id} 
      and ? like concat("% ",shared_terms.text," %") group by shared_terms.text
    SQL
    shared_terms = SharedTerm.find_by_sql([sql," #{(body+processed_body).strip} "])
    
    ret = []
    st_hash = {}
    shared_terms.each{|st|
      match_found=false
      shared_terms.each{|st2|
        if (st2.text.size!=st.text.size) && st2.text.downcase[st.text.downcase] 
          puts "nixing #{st.text}"
          match_found=true
          break
        end
        }
      ret<<st unless match_found
      }
    return ret
  end


end
