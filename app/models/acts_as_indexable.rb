# ActsAsIndexable will automatically create an in-memory index of any given textual content in any class
# simply "include ActsAsIndexable" and then you can search any collection of columns thus:
# class Page
#   include ActsAsIndexable
# end
#
# pages=Page.search('i love ruby',find_by_status('approved'),body)
# this will cause an index to be made of all page.body cells. All records containing the phrase 'i love ruby' will be returned.
# the index is cached at the class level, so if you call it again, the index will not be recreated (even if you specify a different finder_method)
# under the hood, the index is a hash, with all words in the corpus on the left, and an array of ids containing the l-value word on the right.

# ActsAsIndexable.search documentation:
# search the class' corpus, creating it if necessary. 
# arguments:
# => finder_method: the method that will be used to get the records you want to search. default is 'find_all'
# => text_method: the name of the column or method that will return the data to be indexed for a particular row. default is 'body'
# => id_method: the name of the unique identifier row, if it not 'id'.

module ActsAsIndexable
  @@pages=nil
  @@pages_index_hash=nil
  @@last_clear_time=nil

  def word2page(text_method,id_method)
    text = self.send(text_method)
    return if text.nil? or text.strip.empty?
    text=strip_punctuation(text).downcase
    all_words = text.scan(/[A-Za-z0-9]+/) if text # break text down into words
    all_words.each{|word|
     @@word2page[word]||=Hash.new
     @@word2page[word][self.send(id_method)]=true
#      logit "found #{word} in page #{id}"
    } if all_words
  end

  def cache_timeout
    60*60*24
  end

  def clear_index_if_needed
      #logger.info("+++ cache eval")
    if @@last_clear_time.nil? or Time.now - @@last_clear_time > cache_timeout
      logger.info("+++ cleared cache at #{Time.now}")
      puts("cleared cache at #{Time.now}")
      @@pages=nil
      @@pages_index_hash=nil
      @@word2page=nil
      @@last_clear_time=Time.now
    end
  end
  
  def strip_punctuation(text)
      text.gsub(/[\-\,\.\:\/\(\)\!\'\"\;\*\"]/,' ') # replace punctuation with space
  end
  
  # break the search term down into an array of normalized words
  def words(text)
    return nil unless text
    text=text.to_s.strip.downcase
#    return nil if text.size<2
    text=strip_punctuation(text)
    raw_words = text.scan /[^\s]+/
    search_words=Array.new
    raw_words.each{|word| 
      search_words<<word unless %w{the and & of}.include? word #or (word.size<2 and words.size==1)
      }
    search_words=raw_words if search_words.empty?
    return search_words
  end

  # search the class' corpus, creating it if necessary. 
  # arguments:
  # => finder_method: the method that will be used to get the records you want to search. default is 'find_all'
  # => text_method: the name of the column or method that will return the data to be indexed for a particular row. default is 'body'
  # => id_method: the name of the unique identifier row, if it not 'id'.
  def search(term_text,finder_method="find",finder_arguments=:all,text_method="body",id_method="id")
    # one time, create an index of *all* words in the corpus. left side is the word, right side is a comma-delimited list of ids containing the word
    clear_index_if_needed
    if not @@pages
      @@word2page=Hash.new
      @@pages_index_hash=Hash.new
      logit "loading pages ..."
      @@pages =self.class.send(finder_method,finder_arguments)
      logit "found #{@@pages.size} new imported_events"
      @@pages.each_with_index{|page,i|
        @@pages_index_hash[page.id]=i
        page.word2page(text_method,id_method)
#        logit ("created word index for page #{page.id}, hash size is #{@@word2page.size}")
#        break if i>1000
      }
    end
    
    # break the search term down into an array of normalized words
    search_words = words(term_text)

    # if *none* of the words in the term are found in the corpus, break out
    match=true
    search_words=[term_text] if search_words.empty?
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
      # algorithm: go through list of pages that contain this word. for each,
      page_ids_counts = Hash.new
      logit "@@word2page[search_words[0]]:#{@@word2page[search_words[0]].size}"
      @@word2page[search_words[0]].each_key{|num| # for each page that contains the first word in the term
        page_ids_counts[num]=1
        1.upto(search_words.size-1) {|i| # for all the words in the term except the first one
#          logit "search_words[i]:#{search_words[i]}"
#          logit "@@word2page[search_words[i]]:#{@@word2page[search_words[i]].size}"
          # increment count if number is found in this word's list
          if @@word2page[search_words[i]][num]  #is this (subsequent) word found in this page?
#            logit "incrementing count for page_id #{num}"
            page_ids_counts[num]=(page_ids_counts[num]||0)+1 # yes, so increment the pages count
          end
        } 
      }
      # now boil down the qualifying pages (those in which all the term words are found) into an array of ids.
      page_ids_to_search=Array.new
      page_ids_counts.each_key{|num|
        # only bother to scan the whole page if all the words are found on the page
#        logit "eval num #{num}"
        if page_ids_counts[num]==search_words.size
          page_ids_to_search<<num.to_i 
          logit "searching page #{num}"
        end
      }
      
      # loop through the qualifying pages
      down_term_text=term_text.downcase
      matching_pages = Array.new
      matching_pages_hash = Hash.new
      time_start
      page_ids_to_search.each{|num|
        logit "num #{num}"
        page_index = @@pages_index_hash[num]
        logit "page_index: #{page_index}"
        page = @@pages[page_index] # get the page out of the cache instead of the database
        logit "page: #{page.inspect}"
        down_body=page.body.downcase
        next unless down_body
        # actually, finally perform a straight search of the full term on this qualifying page
        found=false
        if term_text.size<3 # special more-time consuming search for 1 + 2 character search terms
          found=true if down_body=~/(^|\s)#{term_text}(\s|$)/ 
        else
          found=true if down_body[down_term_text]
        end
#        logit "~~~~~~~~~page.id #{page.id}"
#        logit "~~~~~~~~~matching_pages_hash[page.id] #{matching_pages_hash[page.id]}"
#        logit "~~~~~~~~~found #{found}"
        page.id
        if page and page.id and found==true and not matching_pages_hash[page.id]
            matching_pages<<page 
            matching_pages_hash[page.id]=true
            logit "found <#{term_text}> (body is #{down_body.size} bytes, starts with '#{down_body[0..200]}')"
        else
            logit "not found <#{term_text}>  (body is #{down_body.size} bytes, starts with '#{down_body[0..200]}')"
        end
      }
      time_end("inner")
    end
    matching_pages
  end
  
  def time_start
    @time = Time.now.to_f    
  end
  
  def time_end(label)
    logit "#{label}: #{(Time.now.to_f-@time)*1000000}"  
  end

  def self.logit(s)
    return
    puts s #if $debug
    logger.info s
  end

  def logit(s)
    return
    puts s #if $debug
    logger.info
  end

end