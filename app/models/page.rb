class Page < ActiveRecord::Base
  belongs_to :place
  has_many :matches
  has_many :future_matches,
           :class_name => "Match",
           :conditions => ["matches.time_status='future' and matches.status='notified'"]

  @@pages=nil
  @@hash_of_word_index_hashes=nil

  def self.find(id)
    sql=<<-SQL
      select id,url,last_crawled_at,place_id,meth,flags,status,year,month,day,num_consecutive_errors,last_changed_at
      from pages where id=#{id}
    SQL
    Page.find_by_sql(sql).first rescue nil
  end
  
  def body
    sql=<<-SQL
      select body
      from pages where id=#{self.id}
    SQL
    pages = Page.find_by_sql(sql)
    pages.first.body_before_type_cast
  end

  def raw_body
    sql=<<-SQL
      select raw_body
      from pages where id=#{self.id}
    SQL
    Page.find_by_sql(sql).first.raw_body_before_type_cast
  end
  
  def source
    nil
  end

  def domain
    url =url(true)
    uri = URI.parse(url)
    domain = uri.host.sub("www.","") rescue ""
    domain = domain[0..32]
    domain
  end

  def url(real_url=false)
    return super
    return super if $mode=="daemon" or real_url
    if place.venue_id 
      return place.venue.affiliate_url_1
    else
      return super
    end
  end

  def self.find_all_problem_pages
    max_errors=0
    max_unchanged_days=60
    sql  = " select pages.* from pages,places "
    sql += " where (num_consecutive_errors>#{max_errors} "
    sql += " or (last_changed_at is not null and last_changed_at<adddate(now(),interval -#{max_unchanged_days} DAY))) "
    sql += " and pages.status='future' " 
    sql += " and place_id=places.id and places.status<>'inactive' "
    sql += " order by place_id"
    Page.find_by_sql(sql)
  end

  def self.find_all_matching_term(term_text,num=-1)
    _term_text = term_text.gsub(/[\-\,\.\:\/\(\)\!\'\"\;\*\"]/," ") # replace punctuation with space
    sql=  " select pages.* from pages,places "
    sql+= " where places.status='active' "
    sql+= " and pages.status='future' "
    sql+= " and body like ? "
    sql+= " order by month asc"
    sql+= " limit #{num} " if num!=-1
    find_by_sql([sql,"% #{_term_text} %"])
#    (:all, :conditions => [ "status='future' and body like ?", 
#                          "% #{term_text} %"],:order => "month asc",:limit =>11)
  end
  
  def precis(query,highlight_left="<strong>",highlight_right="</strong>")
    begin
      query.gsub! /[^\w\d\s]/,' '
      self.body =~ /[\d\D]{0,100}\s#{query}\s[\d\D]{0,100}/i # find the section near the band name
      precis = $&.gsub /(#{query})/i,"#{highlight_left}#{query}#{highlight_right}" if $&
      # now trim off the first and last word, presuming they are just fragments
      precis = precis.sub /^\w+\s/,""
      precis = precis.gsub /\s\w+$/,""
      return precis
    rescue
      return ""
    end
  end

  def fast_precis(query,highlight_left="<strong>",highlight_right="</strong>")
    precis=""
    begin
      query.downcase!
      query.gsub! /[^\w\d\s]/,' '
      start_of_word=body.index(/#{query}/i)
      if not start_of_word
        return "" 
      end
      end_of_word=start_of_word+query.size
      start_of_precis=start_of_word-100
      start_of_precis=0 if start_of_precis<0
      end_of_precis=end_of_word+100
      end_of_precis=body.size-1 if end_of_precis>body.size-1
      precis=body[start_of_precis..end_of_precis].downcase
      precis.gsub! "#{query}","#{highlight_left}#{query}#{highlight_right}" if precis
      precis = precis.sub /^\w+\s/,""
      precis = precis.gsub /\s\w+$/,""
      precis = precis.gsub /\s{2,}/,' '
    rescue
    end
    return precis
  end
  
  def sanitize_body
    # cut out all sections that aren't listings
    #extract_relevant_sections
  end
  
  def extract_relevant_sections
    #
  end
	
	# take a guess at when this event is. 
	# first, if this is a template-based url, look at the month/year/day fields
	# if month and day are present, just return them.
	# if there is only a month, attempt to determine the day
	# if there is no month or day, attempt to determine the month, and hopefully the day.
	# there should be a high degree of certainty to any of this data, err on the side of caution
	
  def calculated_month
	logit "retrieving @calculated_month #{@calculated_month}"  
  @calculated_month
  end

  def calculated_year
    @calculated_year
  end

  def calculated_day
    @calculated_day
  end
	
	def calculate_date_of_event(term)
    if not place
      logit "place is nil, this is wrong, exiting"
      return
    end
    logit("calculating date of event for term "+term)
    
    if year and year>=DateTime.now.year
      @calculated_year = year
    else
      @calculated_year = DateTime.now.year
    end
    if month and day
      @calculated_month=month
      @calculated_day=day
      return "day"
    end
    if month and not day
      logit("month but no day for this page, manually calculating day ... ")
      @calculated_month=month
      determine_date_from_context(term)
      return "day",@calculated_year,@calculated_month,@calculated_day if @calculated_day
	return "month"
    end
    if not month and not day
      logit("no month or day for this page, manually calculating month+day ... ")
      determine_date_from_context(term)
      puts "@calculated_month after determine_date_from_context: #{@calculated_month}"      
      if !@calculated_month
        if place.time_type=="temporary" # festivals
          # give this event a date of the final day of the festival
          return nil if not place.end_date
          @calculated_year=place.end_date.year
          @calculated_month=place.end_date.month
          @calculated_day=place.end_date.day
          return "day",@calculated_year,@calculated_month,@calculated_day
        else 
          return nil
        end
      end
      log_calculated_date      
      return "day",@calculated_year,@calculated_month,@calculated_day if @calculated_day
      return "month"
    end
  end

  def venue_id
    return id # not place_id because some clubs have multiple stages... well, just the middle east
  end
  
  def set_matches_as_future
    Match.update_all("time_status='future'","page_id= #{id}");
  end

  def log_calculated_date
	logit "logging calculated_date"	
logit "@calculated_month: #{calculated_month}"
	logit "@calculated_day: #{calculated_day}"
	logit "@calculated_year: #{calculated_year}"
end

  def date_block
    @date_block
  end
  
  def date_position
    @date_position
  end
  
  def month_position
    @month_position
  end

  def render_date_block(date_block,matches,selected_match)
    matches.each{|match|
      if match[0]==selected_match[0] and match[1]==selected_match[1]
        date_block.gsub!(/(#{match[0]}.#{match[1]})/,'(((((\1)))))')
      else
        date_block.gsub!(/(#{match[0]}.#{match[1]})/,'+++++\1-----')
      end
    }
    date_block
  end

  def render_day_block(day_block,matches)
    matches.each{|match|
      day_block.gsub!(/(#{match})/,'+++++\1-----')
    }
    day_block
  end
  
  def determine_date_from_context(term)
    term.gsub! /[^\w\d\s'@#%]/,'\\1'
    if not place
      logit "place is nil, this is wrong, exiting"
      return
    end
    logit "determine date from context for term #{term}"
    return unless raw_body=~/#{term}/i 
    
    @month_map = place.make_month_map
    potential_date_block_size=2000 
    date_is_after = false
    date_is_after = true if place.date_type=="after"  
    buffered_date_block = ""
    if date_is_after
      logit "date is after"
      date_block=$'
      date_block=date_block[0..potential_date_block_size] if date_block and date_block.length>potential_date_block_size
      buffered_date_block="#{$`[0..100]}[[[[[#{term}]]]]]#{date_block}"
    else
      logit "date is before"
      date_block=$` # this is the part we hope contains a date
      date_block=date_block[-potential_date_block_size..-1] if date_block and date_block.length>potential_date_block_size # just the last several dozen chars
      buffered_date_block="#{date_block}[[[[[#{term}]]]]]#{$'[0..5]}"
    end
#    logit "date_block:"
#    logit date_block
#    logit "buffered_date_block:"
#    logit buffered_date_block
    @buffered_date_block=buffered_date_block
    
    ret=place.calculate_regexps
    all_regexps=ret[:all_regexps]
    month_match_position=ret[:month_match_position]
    day_match_position=ret[:day_match_position]
    @month_match_position=month_match_position
    # returns {:all_regexps=>all_regexps,:month_match_position=>month_map_position,:day_match_position=>day_match_position}
    matches = date_block.scan(/#{all_regexps}/i)
    # getting this error in the above line:
    # invalid regular expression; there's no previous pattern, to which '{' would define cardinality at 
    # 4: /(?:{yyyy}\-([01]?[0-9])\-((?:(?:[123][0-9])|(?:[0][1-9])|(?:[1-9]))(?![0-9])))/
    trimmed_matches=Array.new
    matches.each{|match|      
      trimmed_submatches = Array.new # eliminate any blank matches from parens that were in the 'other' ors in the regexp
      match.each{|submatch| 
        logit "(raw submatch: #{submatch})"
        trimmed_submatches<<submatch if submatch and not submatch.strip.empty?
        }
      trimmed_matches<<trimmed_submatches
    }
    trimmed_matches.each{|match|      
      logit " possible match: #{match[month_match_position]}/#{match[day_match_position]} "
      match.each{|submatch| logit "(trimmed submatch: #{submatch})"}
    }
    if date_is_after
      match=trimmed_matches.first
    else
      match=trimmed_matches.last
    end
    if match 
      logit " chosen match: #{match[month_match_position]}/#{match[day_match_position]} "
      logit "                    day_match_position: #{day_match_position}"
      logit "                    month_match_position: #{month_match_position}"
      
      # we have a match. process the values and return
      # could be number or name - so strip leading zeros AND lowercase it
      @calculated_month = String(match[month_match_position]).sub(/^[0+]/,"").downcase 
      @calculated_month = @month_map[@calculated_month] if @month_map[@calculated_month]
      @calculated_day=String(match[day_match_position]).sub(/^[0+]/,"") if match.size>1 # strip leading zeros
      logit "@calculated_month: #{@calculated_month}"
      logit "@calculated_day: #{@calculated_day}"
      if @month_map[@calculated_month]
        numerical_month=@month_map[@calculated_month]
      else
        numerical_month=Integer(@calculated_month) rescue nil
      end
      # now determine the year. if the month of the event is 1,2 or 3 and the current month is 10, 11 or 12 then increment the year by one.
      if @calculated_year and numerical_month
        @calculated_year=DateTime.now.year+1 if DateTime.now.month>=10 and numerical_month<=3
        # if the month of the event is 10,11 or 12 and the current month is 1, 2 or 3 then decrement the year by one.
        @calculated_year=DateTime.now.year-1 if DateTime.now.month<=3 and numerical_month>=10
      end
      @date_block=render_date_block(buffered_date_block,trimmed_matches,match)
      logit "rendered date block: #{@date_block}"
      return
    end
#          if best_match.nil?
#            best_match=match 
#          else
#            match_index = date_block.index(
#            if date_is_after
#        else
#        end
#      end      
    # if in the end we have not been able to find a proper "may 1" date,
    # see if the month is known from templating and we can just look for the day by itself
    return if just_calculate_day(date_block,date_is_after) if month 
    
#    }
  end

  def header (s)
    line ="****************************************************************"
    logit line
    logit line
    logit "***************** "+s
    logit line
    logit line  
  end

  def build_word_index_hash
    word_index_hash=Hash.new
    all_words = body.scan(/\w+/) if body
    all_words.each{|word|
      word_index_hash[word]=true
#      logit "found #{word} in page #{id}"
    } if all_words
    logit "found #{word_index_hash.size} words on page"
    word_index_hash
  end
  @@word2page = Hash.new

  def word2page
    all_words = body.downcase.scan(/\w+/) if body
    all_words.each{|word|
      @@word2page[word]="#{@@word2page[word]||''},#{id}," unless @@word2page[word] and (@@word2page[word][",#{id},"] or @@word2page[word].size>2000)
#      logit "found #{word} in page #{id}"
    } if all_words
  end

  def self.find_all_future
    Page.find_by_sql("select * from pages where status='future'")
  end

  def self.find_all_matching_term_optimized(term)
    if not @@pages
      @@word2page=Hash.new
      logit "loading pages ..."
      @@pages =Page.find_all_future
      @@pages.each{|page|
        page.word2page
        logit ("created word index for page #{page.id}, hash size is #{@@word2page.size}")
      }
    end
    matching_pages = Array.new
    term_text = term.text_for_searching.to_s.strip.downcase

    words = term_text.scan /[^\s]+/
    search_words=Array.new
    words.each{|word| 
#      logit word 
      search_words<<word unless %w{the and & of}.include? word or (word.size<3 and term_text.size>2)
      }
    match=true
    search_words=words if search_words.empty?
    search_words.each{|search_word|
      logit "search_word: #{search_word}"
      if not @@word2page[search_word]
        match=false
        break
      end
    }
    
    if match
      logit "found first word(s) in hash (#{search_words.collect{|w|' '+w}}), performing complete scan"

      # get pages matching all words -- perform intersection
      page_ids_counts = Hash.new
      logit "@@word2page[search_words[0]]:#{@@word2page[search_words[0]]}"
      @@word2page[search_words[0]].scan(/\d+/).each{|num|
        logit num
        page_ids_counts[num]=1
        1.upto(search_words.size-1) {|i|
          logit "search_words[i]:#{search_words[i]}"
          logit "@@word2page[search_words[i]]:#{@@word2page[search_words[i]]}"
          # increment count if number is found in this word's list
          if @@word2page[search_words[i]].scan(/\d+/).find{|num2|
            #logit num2
            num2.to_i==num.to_i}
            logit "incrementing count for page_id #{num}"
            page_ids_counts[num]=(page_ids_counts[num]||0)+1 
          end
        } 
      }
      logit page_ids_counts.inspect
      page_ids_to_search=Array.new
      page_ids_counts.each_key{|num|
        # only bother to scan the whole page if all the words are found on the page
        logit "eval num #{num}"
        if page_ids_counts[num]==search_words.size
          page_ids_to_search<<num.to_i 
          logit "searching page #{num}"
        end
      }
      page_ids_to_search.each{|num|
        logit "page #{num}"
        page = @@pages.detect{|page|page.id==num.to_i}
        down_body=page.body.downcase
        logit "term_text: <#{term_text}>"
#        logit "body: #{down_body}"
        logit "found term at "
        
        logit down_body.index(" #{term_text} ").inspect
#        logit "found test term at #{down_body.index(' hallelujah the hills ').inspect}"
        if page.body and down_body.index(" #{term_text} ") and not matching_pages.find{|matching_page| matching_page.id==page.id}
          matching_pages<<page 
          logit "found <#{term_text}>"
        else
          logit "not found <#{term_text}>"
        end
      }
    end
    matching_pages
  end
 # select * from pages where status="future" and body like "% asa brebner %"
  def self.find_all_matching_term(term,num=10)
    if term.is_a? String
      term.gsub!("%20"," ")
      return Page.find_by_sql('select * from pages where status="future" and body like "% '+term+' %"')      
    else            
      pages =Page.find_all_matching_term_optimized(term)
      unless pages.empty?
        ids = "-1"
        pages.each_with_index{|page,i|
          ids+=",#{page.id}"
          break if i>num
          }
        pages2 = Page.find_by_sql("select * from pages where id in (#{ids})")
  #      @@optimized_matches[term.text] = pages2
        end
       end
      pages2||Hash.new
  end

  
  def self.report
    logit "optimized report"
    @@optimized_matches.each_key{|term|
      next unless @@optimized_matches[term] and @@optimized_matches[term].size>0
      s = "#{term} on  #{@@optimized_matches[term].size}:"
      @@optimized_matches[term].sort!{|x,y| y.id<=>x.id} 
      @@optimized_matches[term].each{|page|
        s+=" #{page.id}"
      }
      if @@sql_matches[term] and not @@sql_matches[term].empty?
        s+="\t\t\tsql found it on #{@@sql_matches[term].size}:"
      @@sql_matches[term].sort!{|x,y| y.id<=>x.id} 

        @@sql_matches[term].each{|page|
          s+=" #{page.id}"
        }
      else
        error =true
      end
      logit s
      header("mismatch") if error
    }

    logit "sql report"
    @@sql_matches.each_key{|term|
      next unless @@sql_matches[term] and @@sql_matches[term].size>0
      s = "#{term} on"
      @@sql_matches[term].each{|page|
        s+=" #{page.id}"
      }
      if @@optimized_matches[term] and not @@optimized_matches[term].empty?
        s+="\t\t\toptimized found it on"
        @@optimized_matches[term].each{|page|
          s+=" #{page.id}"
        }
      else
        error=true
      end
      logit s
      header('mismatch') if error
    }
  end
  
  def self.find_all_matching_term_using_sql(term)
    Page.find(:all, :conditions => [ "status='future' and body like ?", 
                             "% #{term.text_for_searching} %"])
  end
                             
  def self.logit(s)
    puts s
  end

  def logit(s)
    puts s
  end

  def just_calculate_day(date_block,date_is_after=false)
    logit "month known, looking for days in >2< format ..."
    logit date_block
    day_expression = "([0123]?[0-9])(?:st|nd|rd|th)?"
    regexp=">#{day_expression}<"
    regexp=place.day_regexp if place.day_regexp and not place.day_regexp.chomp.empty?
    regexp.gsub!(/\{day\}/,day_expression) # sub out the string "[day]" in the expression
    matches = date_block.scan(/#{regexp}/) # for example, ">31<" or ">01<"
    return if not matches
    if date_is_after
      match = matches.first
    else
      match = matches.last
    end
    if match
      logit "day matched:"+String(match[0]) if match[0]
      @calculated_day=String(match[0]).sub(/^[0+]/,"") if match[0]; # strip leading zeros
      @date_block=render_day_block(@buffered_date_block,matches)
      logit "rendered day block: #{date_block}"
    end  
  end
  
    def remove_accents(text)
      return if not text
        text.gsub!(/â/,'a')
        text.gsub!(/à/,'a')
        text.gsub!(/á/,'a')
        text.gsub!(/ȁ/,'a')
        text.gsub!(/À/,'A')
        text.gsub!(/Á/,'A')

       text.gsub!(/é/,'e')
       text.gsub!(/è/,'e')
       text.gsub!(/ë/,'e')
       text.gsub!(/ê/,'e')

       text.gsub!(/ì/,'i')
       text.gsub!(/í/,'i')
       text.gsub!(/Ì/,'I')
       text.gsub!(/Í/,'I')
       text.gsub!(/î/,'i')
       text.gsub!(/ï/,'i')
       text.gsub!(/ĩ/,'i')

       text.gsub!(/ò/,'o')
       text.gsub!(/ó/,'o')
       text.gsub!(/ô/,'o')
       text.gsub!(/ö/,'o')
       text.gsub!(/Ò/,'O')
       text.gsub!(/Ó/,'O')
       text.gsub!(/Ö/,'O')

       text.gsub!(/ù/,'u')
       text.gsub!(/ú/,'u')
       text.gsub!(/ü/,'u')
       text.gsub!(/Ü/,'U')
       text.gsub!(/Ú/,'U')
       text.gsub!(/Ù/,'U')

       text.gsub!(/ñ/,'n')
       text.gsub!(/ç/,'c')
       text.gsub!(/Ç/,'Ç')
       text.gsub!(/Ł/,'w')
       text.gsub!(/ł/,'w')
      text
    end  
end  
