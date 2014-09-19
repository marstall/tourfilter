class Term < ActiveRecord::Base


  has_and_belongs_to_many :users
  has_many :terms_users,
           :class_name => "TermsUsers"
  has_many :matches
  has_many :items,:order=>"release_date desc"

  def calculate_num_trackers
    cnt = TermsUsers.count_by_sql("select count(*) from terms_users where term_id=#{self.id}")
    return cnt.to_i
  end

  def self.num_trackers_multiple(term_texts)
    term_texts.each{|text|
      return nil if text=~/select|delete|insert|update|\;/i
    }
    term_texts.collect!{|t|t.gsub "'","\\'"}
    sql = <<-SQL
      select count(*) from terms_users,terms 
      where term_id=terms.id and terms.text in ('#{term_texts.join('\',\'')}','#{term_texts.collect{|t|"the #{t}"}.join('\',\'')}')
    SQL
    TermsUsers.count_by_sql(sql)
  end

  def self.normalize_text(text)
    text.sub! /^the\s/i,"" # remove initial 'the'
    text.gsub! /\&/,"and"  # subs. 'and' for '&'
    text.gsub! /.\/\'/,""      # remove any periods, slashes, apostrophes
    text.gsub! /\s+/," "
    text.strip
  end

  def articles
    Article.find_by_term_text(text)
  end
  
  def dequoted_text
    text.gsub("'","")
  end

  def some_users(num)
    Term.find_by
  end
  
#  def num_trackers
#    (aggregate_num_trackers||0).to_i
#  end

=begin
  select terms.text,terms.num_trackers,count(*) cnt 
  from terms,terms_users 
  where term_id=terms.id and terms_users.created_at>adddate(now(),interval -1 month) 
  and term_id=terms.id and terms_users.created_at<=adddate(now(),interval -0 month) 
  and terms.num_trackers<50
  group by term_id 
  order by cnt desc limit 20;  
=end

  def hot
    sql = <<-SQL
      select terms.text,count(*) cnt 
      from terms,terms_users 
      where term_id=terms.id and terms_users.created_at<adddate(now(),interval -$2 week) 
      and terms_users.created_at>=adddate(now(),interval -$end week) 
      and terms_users.created_at<adddate(now(),interval -$end week) 
      group by term_id 
      order by cnt desc limit 20;  
    SQL
  end

  def delete_image
    sql = <<-SQL
      select * from tourfilter_shared.images images
      where images.term_text=?
    SQL
    images = Image.find_by_sql([sql,text])
    Image.delete(images.first) and return if images.first
    images = Image.find_by_sql([sql,normalized_text]) if images.nil? or images.empty?
    Image.delete(images.first) and return if images.first
    images = Image.find_by_sql([sql,"the #{text}"]) if images.nil? or images.empty?
    Image.delete(images.first) and return if images.first
  end
  
  @@image_term_texts=nil
  
  def cache_image_data
    return if @@image_term_texts
    @@image_term_texts=Hash.new
    sql = <<-SQL
      select * from tourfilter_shared.images
    SQL
    images = Image.find_by_sql(sql)
    return unless images
    images.each{|image|
      @@image_term_texts[image.term_text]=image
    }
  end
  
  def image
      cache_image_data
      return false unless @@image_term_texts
      return @@image_term_texts[text]||@@image_term_texts[normalized_text]||@@image_term_texts["the #{text}"]||nil
  end

  def image_unused
    cache_image_data
    sql = <<-SQL
      select * from tourfilter_shared.images images
      where images.term_text=?
    SQL
    images = Image.find_by_sql([sql,text])
    images = Image.find_by_sql([sql,normalized_text]) if images.nil? or images.empty?
    images = Image.find_by_sql([sql,"the #{text}"]) if images.nil? or images.empty?
    images.empty? ? nil :images[0]
  end

  def self.find_all_with_upcoming_show_and_no_url
    Term.find_by_sql <<-SQL
      select terms.* 
      from terms,matches,pages,places 
      where matches.page_id=pages.id 
      and pages.place_id=places.id 
      and terms.id=matches.term_id 
      and matches.status='notified' and matches.time_status='future' 
      and terms.url is null;    
      SQL
  end
  
  def find_and_save_myspace_url
    
  end


  def find_items_by_name(text)
    sql = <<-SQL
      select * from items 
      where term_text=?
      and items.artist=?
      and items.medium_image_url is not null
      and length(items.medium_image_url)>0
      group by title 
      order by release_date desc
    SQL
    Item.find_by_sql([sql,text,text]) 
  end

  def exact_items
    items = find_items_by_name("the #{text}")
    return items unless items.nil? or items.empty?
    find_items_by_name(text)
  end

  
#  has_many :recent_matches, # matches less then one month old
#           :class_name => "Match",
#           :conditions => ["matches.created_at > ?", 2.months.ago]
#  has_many :future_matches, # matches less then 4 months old that are still "in the future"
#                    :class_name => "Match",
#                    :conditions => ["status = 'future'"]
  
           
  #def recent_matches
  #  return if not id
  #  sql = "select matches.* from matches where matches.created_at>? and term_id=?"
  #  Match.find_by_sql([sql,2.months.ago,id])
  #end
  
  def self.find_by_first_letter(first_letter)
    return unless first_letter and first_letter.size==1
    Term.find_by_sql <<-SQL
      select * from terms
      where text like "#{first_letter}%"
      order by text asc
    SQL
  end

  @@related_terms_combo=Hash.new

  def featured?
    Feature.find_by_term_text(text)
  end

  def related_terms_combo(num=50)
#    return @@related_terms_combo[text] if @@related_terms_combo[text]
    #ranking is
    # first, any rt with both count and played_with count, in order of played_with_count
    # then, one played_with
    # then, the rest based on shared followers
    return unless id||text
    t=text.gsub("\"","\\\"")
    rts = RelatedTerm.find_by_sql <<-SQL
      select * from related_terms
      where term_text="#{t}"
      and count>0 and played_with_count>0
      order by played_with_count desc
     SQL
     rts+=RelatedTerm.find_by_sql <<-SQL
       select * from related_terms
       where term_text="#{t}"
       and played_with_count>0
       order by played_with_count desc
       limit 1
      SQL
 #    @@related_terms_combo[text] = 
#     return @@related_terms_combo[text]
    return rts+related_terms(num-rts.size)
  end

  def related_terms(num=50)
    return unless id||text
    t=text.gsub("\"","\\\"")
    RelatedTerm.find_by_sql <<-SQL
      select * from related_terms
      where term_text="#{t}"
      order by count desc
      limit #{num}
     SQL
  end
  
  def find_related_terms_terms(num=50)
    return unless id
    related_terms = Term.find_by_sql <<-SQL
      select terms.* from terms,tourfilter_shared.related_terms related_terms
      where term_text="#{text}"
      and related_term_text=terms.text
      order by count desc
      limit #{num}
     SQL
    return related_terms
  end

  def normal_users
    sql =  " select users.* from users,terms_users "
    sql += " where terms_users.term_id=? and terms_users.user_id=users.id "
    sql += " and users.registration_type<>'basic' "
    User.find_by_sql([sql,id]) 
  end

  def recent_normal_users(limit=100)
    return if not id
    sql =  " select users.* from users,terms_users,terms " +
           " where users.id=terms_users.user_id " +
           " and users.registration_type<>'basic' " +
           " and terms.id = #{id}" +
           " and terms.id=terms_users.term_id order by terms_users.created_at desc" +
           " limit #{limit}"
           
    return User.find_by_sql(sql)
  end

  def validate
    text !~ /http|href|cialis|viagra|url/i
  end
  
  def has_users?
    ! TermsUsers.find_by_sql(["select * from terms_users where term_id=? limit 1",id]).empty?
  end

  def self.count_all
    Match.count_by_sql("select count(*) from terms")
  end
  
  def mp3_tracks(source_reference=nil)
    sql = " select * from tracks where type='mp3' and term_id=?"
    sql +=" and source_reference= " if source_reference
    params=[sql,id]
    params<<source_reference if source_reference
    Track.find_by_sql(params)
  end

  def recent_users
    return if not id
    sql =  " select users.* from users,terms_users,terms " +
           " where users.id=terms_users.user_id " +
           " and terms.id = #{id}" +
           " and terms.id=terms_users.term_id order by terms_users.created_at desc"
    return User.find_by_sql(sql)
  end
  
  def self.all_alpha
    Term.find(:all,:order=>"text asc")
  end
  
  def self.find_related_terms(terms)
    terms=[terms] unless terms.is_a? Array 
    related_terms=Array.new
    related_terms_hash=Hash.new
    related_terms_culled_array_of_arrays = Array.new
    terms[0..40].each{|term|
      _related_terms_culled=Array.new
      if term.is_a? Term
        _related_terms=term.related_terms(7)
#        logger.info(term.text)
      else 
        _related_terms=RelatedTerm.find_all_by_term_text(term,:order=>"count desc",:limit=>7)
#        logger.info(term)
      end
      _related_terms.each{|related_term|
        if not related_terms_hash[related_term.related_term_text]
 #         logger.info(" ... added+#{related_term.term.text}")
          _related_terms_culled<<related_term 
          related_terms_hash[related_term.related_term_text]=true
        end
      }
      related_terms_culled_array_of_arrays<<_related_terms_culled
    }
#    for i in (0..9) 
#      logger.info(i)
      related_terms_culled_array_of_arrays.each{|array|
        array.each{|rt|
#        logger.info(array[i].related_term.text)
        related_terms<<rt # if array.size+1>=i and array[i] # interleave
      }
      }
#    end
    return related_terms
  end
  
  def played_with_terms
    # go through each venue
    # for each venue, get each day that has a show
    # get all the bands that have a show on that day
      sql = <<-SQL
        select terms.id id,terms.text text,count(*) cnt
        from terms, matches matches1,matches matches2 
        where terms.id=matches2.term_id 
        and matches2.page_id=matches1.page_id 
        and matches1.date_for_sorting = matches2.date_for_sorting
        and matches1.id=#{id}
        and matches2.id<>#{id}
        and matches2.status='notified'
        group by terms.text
        limit #{num}
      SQL
      Term.find_by_sql(sql)    
#      Term.uniques(terms)
  end


  def generate_related_terms
    #puts "generating related terms for '#{text}'..."
#    puts "generating related terms via shared bills"
#    generate_related_terms_from_shared_bills
    sql = " select * from terms_users "
    sql += " where term_id=#{id} "
    terms_users = TermsUsers.find_by_sql(sql)
    return unless terms_users and not terms_users.empty?
    user_ids = terms_users.collect{|terms_user|terms_user.user_id}.join(",")
    sql =  " select terms.id id,terms.text text,count(*) cnt from terms_users,terms "
    sql += " where terms_users.term_id=terms.id "
    sql += " and user_id in "
    sql += " (#{user_ids}) and terms.id<>#{id} "
    sql += " group by terms.text order by cnt desc limit 100; "
#    puts sql
    results = Term.find_by_sql(sql)
#    results += played_with_terms
    results.each {|result|
     # puts " ... #{result.text} (#{result.cnt})"
      related_term = RelatedTerm.new
#      related_term.term_id=id
      related_term.term_text=text
 #     related_term.related_term_id=result.id
      related_term.related_term_text=result.text
      related_term.count=result.cnt
      related_term.save
    }
  end
  
  def track
    tracks =  tracks(1)
    return tracks[0] if not tracks.empty?
    return nil
  end
  
  def tracks(num=10)
    tracks = Track.find_by_term(self,'mp3',nil,1,true)
    return tracks
  end
  
  
  def self.find_all_with_hype_tracks
    return Term.find_by_sql(" select terms.* from terms where terms.num_mp3_tracks>0 ")
  end
  
  def feature
    Feature.find_by_term_text(text)||Feature.find_by_term_text(text.gsub(/the/i,"").strip)
  end

  def played_with(num=1000)
    sql = <<-SQL
    select terms2.*,count(*) cnt
    from terms terms1,terms terms2, matches matches1,matches matches2 
    where terms2.id=matches2.term_id 
    and matches2.page_id=matches1.page_id 
    and matches1.date_for_sorting = matches2.date_for_sorting
    and terms1.id=matches1.term_id
    and terms1.id=#{id}
    and terms2.id<>#{id}
    and matches1.status='notified' and matches2.status='notified'
    group by terms2.text order by cnt desc
    limit #{num}
    SQL
    Term.find_by_sql(sql)
  end

  def past_matches(num=-1)
    return if not id
    sql = <<-SQL
      select matches.* from matches
      where matches.status='notified' and matches.time_status<>'future' 
      and date_for_sorting<now() 
      and matches.term_id=#{id} 
      order by matches.date_for_sorting desc
      SQL
    sql+= " limit #{num}" if num!=-1
    return Match.find_by_sql(sql)
  end
    
  def future_matches(num=-1)
    return if not id
    sql = <<-SQL
      select matches.* from matches
      where matches.status='notified' and matches.time_status='future' and matches.term_id=#{id} 
      and date_for_sorting>=adddate(now(),interval -1 day)
      order by matches.date_for_sorting desc
      SQL
    sql+= " limit #{num}" if num!=-1
    return Match.find_by_sql(sql)
  end
  
  def self.encode(text)
    term = Term.new
    term.text=text
    return term.encoded_text
  end

  def encoded_text
    t =text.downcase # make it all lowercase
    t=t.gsub(/\s/,"+") #substitute + for spaces
    t=t.gsub(/[\/]/,"+") #substitute + for spaces
  end

  def text_nobreak
    text.gsub(' ','&nbsp;')
  end

  def url_text
    t =text.downcase # make it all lowercase
    t=t.gsub(/\s/,"-") #substitute underscores for spaces
    t=t.gsub(/[\/]/,"-") #substitute underscores for spaces
    t
  end

  def url_text_old
    t =text.downcase # make it all lowercase
    t=t.gsub(/\s/,"_") #substitute underscores for spaces
  end
  
  def text_no_quotes
    text.gsub /["']/, ""
  end
  
  def self.normalize_text(text)
    text.sub! /^the\s/i,"" # remove initial 'the'
    text.gsub! /\&/,"and"  # subs. 'and' for '&'
    text.gsub! /[.\/-]/," "      # remove any periods, slashes
    text.gsub! /\s+/," "
    text.strip
  end

  def normalized_text
    Term.normalize_text(text)
  end

  def self.initial_capsify(text)
    ret = ""
    text.each(" "){|word|
#      logger.info("word: #{word}")
      ret+=" "
      ret+=word.strip.capitalize
    }
    ret.strip
  end

  def text_with_initial_caps
    Term.initial_capsify(text)
  end

  def self.make_wikipedia_url_text(text)
    term = Term.new
    term.text=text
    return term.wikipedia_url_text
  end

  def self.make_url_text(text)
    term = Term.new
    term.text=text
    return term.url_text
  end

  def self.make_url_text(text)
    term = Term.new
    term.text=text
    return term.url_text
  end


  def wikipedia_url_text
    t =text.downcase # make it all lowercase
    t=t.gsub(/\s/,"_") #substitute underscores for spaces
    t.gsub(/((:?^|_).)/) {|s| $1.upcase} # capitalize the letter after where the space was and also the first letter
  end

   def find_tracks_with_filenames
    sql = " select * from tracks where term_text=? and filename is not null "
    Track.find_by_sql([sql,text])
  end 
  def text_for_searching
      text.gsub(/[\-\,\.\:\/\(\)\!\'\"\;\*\"]/,' ') # replace punctuation with space
  end
  

  def text_with_the
    term = Term.find_by_text("the #{self.text}")
    if term
      return term.text.strip
    else
      return self.text.strip
    end
  end
  
  def same_as(term2)
    text1=normalized_text.downcase
    text2=term2.normalized_text.downcase
    text1==text2||text1[text2]||text2[text1]
  end
  
  def self.uniques(terms) # extract only unique band names
    ret = Array.new
    terms.each_with_index{|term,i|
      the_same=false
      terms.each_with_index{|term2,j|
        the_same=true and break if i!=j and term.same_as(term2)
      }
      ret<<term if not the_same
    }
    ret
  end
  
  def words
    raw_words = text_for_searching.to_s.strip.downcase.scan /[^\s]+/
    search_words=Array.new
    raw_words.each{|word| 
      search_words<<word unless %w{the and & of}.include? word or (word.size<3 and term_text.size>2)
      }
    search_words=raw_words if search_words.empty?
    return search_words
  end
  
  
  def before_save
    remove_accents
    text = text.gsub(/<([^>]+)>/," ") if text # get rid of all html
    return false if not validate
  end

  def self.remove_accents(text)
    term = Term.new
    term.text=text
    term.remove_accents
    return term.text
  end
  
  def remove_accents
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
     
     #    text.gsub!(/[ĄÀÁÂÃâäàãáäåāăąǎǟǡǻȁȃȧẵặ]/,'a')
     #    text.gsub!(/[Ęëêéèẽēĕėẻȇẹȩęḙḛềếễểḕḗệḝ]/,'e')
#    text.gsub!(/[ÌÍÎĨÏiìíîĩīĭïỉǐịįȉȋḭɨḯ]/,'i')
#    text.gsub!(/[ÒÓÔÕÖòóôõōŏȯöỏőǒȍȏơǫọɵøồốỗổȱȫȭṍṏṑṓờớỡởợǭộǿ]/,'o')
#    text.gsub!(/[ÙÚÛŨÜùúûũūŭüủůűǔȕȗưụṳųṷṵṹṻǖǜǘǖǚừứữửự]/,'u')
#    text.gsub!(/[ỳýŷỹȳẏÿỷẙƴỵ]/,'y')
#    text.gsub!(/[œ]/,'oe')
#    text.gsub!(/[ÆǼǢæ]/,'ae')
#    text.gsub!(/[ñǹńŃ]/,'n')
#    text.gsub!(/[ÇçćĆ]/,'c')
#    text.gsub!(/[ß]/,'ss')
#    text.gsub!(/[œ]/,'oe')
#    text.gsub!(/[ĳ]/,'ij')
#    text.gsub!(/[Łł]/,'l')
#    text.gsub!(/[śŚ]/,'s')
#    text.gsub!(/[źżŹŻ]/,'z')
    text
  end
end
 
