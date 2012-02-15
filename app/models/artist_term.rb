class ArtistTerm < ActiveRecord::Base
   establish_connection "shared" unless $mode=="import_daemon"
   
   belongs_to :imported_event
   
#   def imported_event
#     ImportedEvent.find(imported_event_id)
#   end

   def calculate_match_probability
     # two heuristics: 
     # 1 is are their multiple words in term_text? if so, mark as probable
     # if not, does it match the anchor regexp? if so, mark as probable
     # else, mark as improbable
     
     # multiple words?
     anchor_regexp = "(featuring|plus|the|presents|with|plus|and|\,|\&|[()]|\/|\:|\-|^|$)"
     nix_regexp = "parking|\svs\.?\s"    
     if artist_name=~/#{nix_regexp}/i
       self.match_probability="unlikely"
       return nil
     end
     text=term_text.strip
     if text[" "]
       self.match_probability="likely"
       return "multpl"
     end
     if artist_name=~/#{anchor_regexp}\s*#{text}\s*#{anchor_regexp}/i
       self.match_probability="likely"
       return "regexp"
     end
#     if artist_name=~/#{anchor_regexp}\s+?#{text}\s+?#{anchor_regexp}/i
#       match_probability="likely"
#       return "regexp"
#     end
     self.match_probability="unlikely"
     return nil
   end
   
  def self.find_matches_by_term(term_text)
    sql = <<-SQL
      select artist_terms.id,artist_terms.imported_event_id,term_text,artist_name,imported_events.url,venues.name,
        imported_events.date,venues.city,venues.state
      from artist_terms,imported_events,venues 
      where artist_terms.imported_event_id=imported_events.id 
        and imported_events.venue_id=venues.id 	
        and artist_terms.term_text like ?
      order by term_text asc
    SQL
    find_by_sql([sql,"%#{term_text}%"])
  end

  def self.find_matches_by_probability(probability,order_by,offset='0',num='1000000')
   order_by||="imported_events.source,venues.state,venues.city,venues.name,artist_name asc"
   find_by_sql( <<-SQL
    select artist_terms.id,term_text,artist_terms.imported_event_id,artist_name,imported_events.url,venues.name,
      imported_events.date,venues.city,venues.state
    from artist_terms,imported_events,venues,metros_venues
    where artist_terms.imported_event_id=imported_events.id 
    and imported_events.venue_id=venues.id
    and venues.id=metros_venues.venue_id 	
    and artist_terms.status='new' 
	  and imported_events.date>now()    
    and artist_terms.match_probability="#{probability}"
    group by artist_terms.id
    order by #{order_by}
    limit #{num}
    offset #{offset}
    SQL
  )
  end

  def self.find_likely_matches(order_by,offset,num)
    find_matches_by_probability("likely",order_by,offset,num)
  end 

  def self.find_unlikely_matches(order_by)
    find_matches_by_probability("unlikely",order_by)
  end 
end
