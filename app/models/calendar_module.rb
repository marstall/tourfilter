module CalendarModule
  def setup_calendar(user=nil,place=nil,num=180,offset=0,limit=10000,order_by="date_for_sorting asc",options={})
    @days=Array.new
    @matches=Hash.new
#    places = Place.find_all_active
    _matches=Array.new
    if place
      _matches=place.current_matches
    elsif options[:term]
      if options[:past]
        _matches=options[:term].past_matches
      else
        _matches=options[:term].future_matches
      end
    else
      _matches=Match.matches_within_n_days_for_user(num,offset,user,"#{order_by},page_id",limit)
    end
    @matched_term_ids=Hash.new
    # strip "the" off beginning of matches
    # don't list same match twice on the same day
    day_terms=Hash.new
    _matches.each{|match|
      next unless match.day
	    next unless match.term_text
      term_text=Term.normalize_text(match.term_text)
      next if day_terms["#{match.date_for_sorting_date_only}:#{term_text.downcase}"]
      day_terms["#{match.date_for_sorting_date_only}:#{term_text.downcase}"]=true
      if not @matches[match.date_for_sorting_date_only]
        @days<<match.date_for_sorting_date_only 
        @matches[match.date_for_sorting_date_only]=Array.new
      end
      @matches[match.date_for_sorting_date_only]<<match
      @matched_term_ids[match.term_id]=true
    } if _matches
    @matches.each_key{|key|
      @matches[key].sort!{|x,y|
        Term.normalize_text(x.term_text).downcase<=>Term.normalize_text(y.term_text).downcase
      }
    }
    [@days,@matches]
  end

  # should return shows sorted by popularity of all artists in show together
  # matches within each show should be sorted by popularity descending ...
  def setup_calendar_collated(user=nil,place=nil,num=90,offset=0,limit=10000,order_by="date_for_sorting asc",options={})
    days,matches = setup_calendar(user,place,num,offset,limit,order_by,options)
    logit "found #{days.size} days, #{matches.size} matches"
    shows=Hash.new
    days_venue_ids = Hash.new #  list of venues having shows on each day
    logit "looping through days..."
    match_venue_ids=Hash.new
    venue_ids_matches = Hash.new
    venue_ids_names=Hash.new # relation between venue_id and name for venue name deduping
      days.each{|day|
        logit "#{day.month}/#{day.day}"
        shows[day]||=Hash.new # the shows for this day
        matches[day].each{|match| # for each of the bands playing in this show ...
          page = match.page
          next if page.nil?
          venue_id=page.venue_id
          match_venue_ids[match.id]||=venue_id # this show is playing at this venue
          venue_ids_names[venue_id]=match.page.place.name rescue 'n/a'
          shows[day][venue_id]||=Array.new # the shows that are at this venue today
          venue_ids_matches[venue_id]||=Array.new # the bands that are playing at this venue on all days
          venue_ids_matches[venue_id]<<match # add this band's appearance to the list of bands playing at the venue
          shows[day][venue_id]<<match # add this band appearance to that days' show for the venue id
        }
      }
      
    #now, combine venues with very similar names (tt the bear's place and tt the bear's, for example)
    # kludge to except the middle east for now
#    logger.info("+++ checking #{venue_ids_matches.size()} venue names for dupes")
    days.each{|day|
      shows[day].each_key{|venue_id|
       venue_name=simplify(venue_ids_names[venue_id])
       next if venue_name=~/middleeast/i
       venue_ids_names.each_key{|venue_id2|
         next if venue_id==venue_id2
         venue_name2=simplify(venue_ids_names[venue_id2])
         if venue_name and venue_name2 and venue_name[venue_name2]
#           logger.info("\t\t\t\tvenue_name2: #{venue_name2}")
           venue_ids_matches[venue_id]+=venue_ids_matches[venue_id2] if venue_ids_matches[venue_id] and venue_ids_matches[venue_id2]
           shows[day][venue_id]+=shows[day][venue_id2] if shows[day][venue_id] and shows[day][venue_id2]
           venue_ids_matches.delete(venue_id2)
           shows[day].delete(venue_id2)
           shows
         end
         }
       }
     }


   #loop through all matches, collapsing dupe names
   if true
     days.each{|day|
       matches[day].each_with_index{|match1,i| # for each of the bands playing in this show ...
         matches[day].each_with_index{|match2,j|
           page = match2.page
           next if page.nil?
           venue_id1 = page.venue_id
           venue_id2 = match2.page.venue_id
       #    next unless venue_id1==venue_id2
           term1=simplify(match1.term_text)
           term2=simplify(match2.term_text)
           next unless term1 and term2
           if term1[term2] and i!=j 
              venue_ids_matches[venue_id2].delete(match2) if venue_ids_matches[venue_id2]
              shows[day][venue_id1].delete(match2)  if shows[day][venue_id1]
           end
         }
       }
     }
   end


   if true
      # loop through each day, compile a list of venues that have a show that day
      shows.each_key{|day| # loop through the days that have shows
        logit "#{day.month}/#{day.day} has #{shows[day].size} shows"
        days_venue_ids[day]||=Array.new # list of venues having shows on this day
        shows[day].each_key{|venue_id| # for each venue having shows
          days_venue_ids[day]<<venue_id # add it to the list of venues having shows on this day
        }
    }
   end

=begin
    days_venue_ids.each_key{|day|
      days_venue_ids[day].sort!{|x,y|
        x_match=y_match=nil
        x_match = shows[day][x].find{|match|match_image(match)} # of the matches that make up a show, pick one that has an image
        y_match = shows[day][y].find{|match|match_image(match)} # of the matches that make up a show, pick one that has an image
        x_match||=shows[day][x].first
        y_match||=shows[day][y].first
        if x_match and y_match
          x_factor = (match_featured(x_match) ? 100000 : 0) # jimmy so ones with images are sorted first
          y_factor = (match_featured(y_match) ? 100000 : 0)
          x_factor += x_match.num_trackers
          y_factor += y_match.num_trackers
          y_factor<=>x_factor # descending
        else
          0
        end
      }
    }
  end
=end
    # now sort matches within show, most popular to least
    if true
      shows.each_key{|day|
        shows[day].each_key{|venue_id|
          shows[day][venue_id].sort! {|x,y| 
          y_term = y.term
          x_term = x.term
          y_factor = y_term.image ? 100000 : 0 # jimmy so ones with images are sorted first
          x_factor = x_term.image ? 100000 : 0
          y_factor += y_term.num_trackers
          x_factor += x_term.num_trackers
          y_factor<=>x_factor
          }
        }
      }
    end
    
        # NOTE TO SELF ... DON'T KNOW WHY SHOWS CAN SOMETIMES CONTAIN NO MATCHES ... TAKE IT FROM HERE, DAYTIME CHRIS!

        if true
        # now sort shows in each day by whether there is an feature, num trackers
          days_venue_ids.each_key{|day|
            days_venue_ids[day].sort!{|x,y|
              shows[day][y].first.num_trackers<=>shows[day][x].first.num_trackers rescue 0
    #          x_match=y_match=nil
    #          x_match = shows[day][x].find{|match|match_featured(match)} # of the matches that make up a show, pick one that has an image
    #          y_match = shows[day][y].find{|match|match_featured(match)} # of the matches that make up a show, pick one that has an image
    #          x_match||=shows[day][x].first
    #          y_match||=shows[day][y].first
    #          if x_match and y_match
    #            x_factor = (match_featured(x_match) ? 100000 : 0) # jimmy so ones with images are sorted first
    #            y_factor = (match_featured(y_match) ? 100000 : 0)
    #            x_factor += x_match.num_trackers 
    #            y_factor += y_match.num_trackers
    #            y_match.num_trackers<=>x_match.num_trackers  # descending
    #          else
    #            0
    #          end
            }
          }
        end
  
    
    return days,days_venue_ids,shows
  end

  def matches2calendar(_matches)
    days=Array.new
    matches=Hash.new
#    matched_term_ids=Hash.new
    _matches.each{|match|
      next unless match.day
      if not matches[match.date_for_sorting]
        days<<match.date_for_sorting 
        matches[match.date_for_sorting]=Array.new
      end
      matches[match.date_for_sorting]<<match
#      matched_term_ids[match.term_id]=true
    }
    return [days,matches]
  end

  def logit(val)
    #puts val
    #logger.info(val)
  end

  def xxx_fragment_of(existing_matches,_match)
    term_text = _match.term_text
    existing_matches.each{|match|
      existing_text = Term.normalize_text(match.term_text)
      new_text = Term.normalize_text(term_text)
#      logger.info " +++ existing_text: #{existing_text}"
#      logger.info "+++ new_text: #{new_text}"
      if existing_text[new_text]
#        logger.info " +++ returning existing_text: #{existing_text}"
        return existing_text
      end
    }
    return false
  end

  def match_featured(match)
    match.feature_id
  end

  def match_image(match)
    @match_images||=Hash.new
    if @match_images[match.id]
      if @match_images[match.id]=='false'
        return nil
      else
        return @match_images[match.id] 
      end
    end
    image = match.term.image
    if image
      @match_images[match.id] = image
      return image
    else
      @match_images[match.id] = 'false'
      return nil
    end
  end
    
  def simplify(s)
    #prepare band names for matching. get rid of non-alpha characters, vowels?
    return "" unless s
    r = s.gsub("the","")
    r = r.gsub(/[^a-z]/i,'').downcase.strip
#    logger.info("simplified: #{s}:#{r}")
    return r if r.size>0
    return s
  end
  

end