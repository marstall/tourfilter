class User < ActiveRecord::Base

  validates_format_of :name,
                      :with => /^[\w\d-]+$/,
                      :message => " is missing or invalid"
  validates_format_of :password,
                      :with => /^[\w\d-]+$/,
                      :message => " is missing or invalid"
  validates_exclusion_of :password,
                      :in =>"Password",
                      :message => " is missing"
  validates_exclusion_of :name,
                      :in =>"Username",
                      :message => " is missing"

  validates_length_of :name, :in => 4..16
  validates_length_of :password, :in => 4..20
  validates_format_of :email_address,
                      :with => /^.+@.+\..+$/,
                      :message => " is missing or invalid"
  validates_uniqueness_of :email_address,
                      :message => " is already in use"
  validates_uniqueness_of :name,
                      :message => " is already in use",
                      :if => Proc.new { |user| user.registration_type !~/basic/ }
# SELECT * FROM `terms` INNER JOIN terms_users 
# ON terms.id = terms_users.term_id 
# WHERE (terms_users.user_id = 225 ) ORDER BY terms_users.created_at desc


#  has_and_belongs_to_many :terms,
#                          :order=>"terms_users.created_at desc"
  has_many :terms_users,
           :class_name => "TermsUsers"
  has_many :matches
  has_many :new_matches, # matches with a status of 'new'
           :class_name => "Match",
           :conditions => "status='new'"
  has_many :recent_matches, # notified, future matches ordered by created_at
            :class_name => "Match",
            :conditions => "status='notified' and time_status='future' and date_for_sorting>now()",
            :order=>'id desc'
  has_many :recommendations
  
  
  @metro_code = nil
  attr_accessor :metro_code 
   
  def email_address
    super.gsub(/\s+/,"").strip
  end

  @terms=nil
  @term_texts_hash=nil
  @num_terms=nil
  def num_terms
    return @num_terms if @num_terms
    @num_terms = term.size
    return
  end
  
  def cache_terms(terms)
    return if @terms
    @terms=terms
    @term_texts_hash=Hash.new
    @terms.each{|term|
      @term_texts_hash[term.text]=term
      }
    return @terms
  end
  
  def clear_terms_cache
    @terms=nil
    @term_text=nil
  end

  def terms(order="terms_users.created_at asc",cache=false)
    return @terms if @terms and cache
    sql = <<-SQL
      select terms.* from terms,terms_users
      where terms.id=terms_users.term_id
      and terms_users.user_id=#{self.id}
    SQL
    sql+="order by #{order}" if order
    if cache
      return cache_terms Term.find_by_sql(sql)
    else
      return Term.find_by_sql(sql)
    end
  end
  
  def terms_hash
    h=Hash.new
    terms.each{|term|h[term.text.downcase]=term}
    h
  end

  def render_errors
    s = "<ul>"
  	errors.each{|error|
  	  s+="<li>#{error}</li>"
    }
    s+="</ul>"
  end

  def User.recent(start=0,num=10)
    sql =  " select * from users order by id desc"
    sql += " limit #{num} "
    User.find_by_sql(sql)
  end

  def User.find_all_admins
    sql = " select * from users where privs like '%admin%' "
    User.find_by_sql(sql)
  end
  def current_recommended_matches(num=-1)
    sql = " select matches.* from recommendations,matches "
    sql+= " where recommendations.match_id=matches.id and date_for_sorting>=now() "
    sql+= " and recommendations.user_id=#{id} "
    sql+= " group by matches.term_id order by date_for_sorting asc "
    sql+= " limit #{num} " if num!=-1
    Match.find_by_sql(sql)
  end

  def current_recommendations(num=50)
    sql = " select recommendations.* from recommendations,matches "
    sql+= " where recommendations.match_id=matches.id and date_for_sorting>=now() "
    sql+= " and recommendations.user_id=#{id} "
    sql+= " group by matches.term_id order by date_for_sorting asc limit #{num} "
    Recommendation.find_by_sql(sql)
  end
  
  def User.generate_autologin_code
    # generate a random 8-character alphanum string, like 57aAN9m0
    # 218,340,105,584,896 (218 trillion) combos
    s=""
#    require 'Random'
    0.upto(7).each{|i|
      r = rand(62)
      if r<10 # for 0-9
        r+='0'.ord # ascii value of 0
      elsif r>=10 && r<36
        r-=10
        r+='a'.ord # ascii value of a
      else 
        r-=36
        r+='A'.ord # ascii value of A
      end
      s+=r.chr
    }
    return s
  end
  
  def email_stats
    sql = <<-SQL
      select count(*) num_emails,min(created_at) first_notification_date from events where user_id=? and object_type='email';
    SQL
    users = User.find_by_sql([sql,self.id])
    user = users[0]
    return user.num_emails,user.first_notification_date
  end
  
  def reset_autologin_code
    if !self.autologin_code
      my_id = self.id
      self.autologin_code = User.generate_autologin_code
      User.update_all("autologin_code='#{self.autologin_code}'","id=#{self.id}")
      test_user = User.find(my_id)
    end
    return self.autologin_code
  end

  def self.onetime_identify_by_autologin_code(autologin_code)
    return nil if autologin_code==nil
    # find user with this autologin code - if found, nil it out and return user, else return nil
    users = User.find_by_sql(["select * from users where binary autologin_code=?",autologin_code]) # case sensitive
    return nil if users.empty?
    user = users[0]
    logger.info ("+++ setting autologin_code to nil for #{user.name}")
    User.update_all("autologin_code=null","id=#{user.id}")
    return user
  end

  def tracks_term(term_text)
    terms(nil,true) # make sure hash is loaded
    @term_texts_hash[term_text]
  end
  
  @@last_user=nil
  @@last_user_common_terms=nil
  
  
  def recommended_users
    user_common_terms = Hash.new
    users=Array.new
    user_ids_used=Hash.new
    terms.each{|term|
      term.normal_users.each_with_index{|user,i|
        next if user.id==self.id
#        break if i>100
        user_common_terms[user.name]||=Array.new
        user_common_terms[user.name]<<term
        users<<user unless user_ids_used[user.id]
        user_ids_used[user.id]=true
        }
      }
    if users.nil? or users.empty?
      return @@last_users,@@last_user_common_terms
    else
      users.sort!{|x,y| user_common_terms[y.name].size <=> user_common_terms[x.name].size}
      users.each{|user| puts user.name}
      @@last_user=users
      @@last_user_common_terms=user_common_terms
      return users,user_common_terms
    end
  end
  
  def recommenders
    sql =  " select users.* from users, recommendees_recommenders rr"
    sql += " where users.id=rr.recommender_id and rr.recommendee_id=#{id} order by rr.id desc"
    users = User.find_by_sql(sql)
  end

  def recommendees
    sql =  " select users.* from users, recommendees_recommenders rr"
    sql += " where users.id=rr.recommendee_id and rr.recommender_id=#{id} order by rr.id desc"
    users = User.find_by_sql(sql)
  end
  
  def is_recommender(user) # can take either a user object or an id ... returns true is user is a recommender to self
    user=User.find(user) if (user.is_a? Integer)
    # is there a recommendee row with user as the recommendee
    # and this as the recommender?
    rr = RecommendeesRecommenders.find_by_recommendee_id_and_recommender_id(id,user.id)
    !rr.nil?
  end

  def is_recommendee(user) # can take either a user object or an id ... returns true is user is a recommendee to self
    user=User.find(user) if (user.is_a? Integer)
    # is there a recommendee row with user as the recommendee
    # and this as the recommender?
    rr = RecommendeesRecommenders.find_by_recommendee_id_and_recommender_id(user.id,id)
    !rr.nil?
  end
  
  def is_admin
    privs and privs=="admin"
  end
  
  def terms_as_text
    s="";
    self.terms("terms_users.created_at asc",false).each{ |p| s+="#{p.text.strip}\n" }
    s
  end

  def terms_as_text=(_terms_as_text)
    @terms_as_text=_terms_as_text
  end

  def terms_as_text_alpha
    s="";
    terms_alpha.each{ |p| s+="#{p.text.strip}\n" }
    s
  end
  
  def terms_as_text_sentence
    terms_alpha.collect{|term|term.text}.join(",")
  end
  
  #deleted_terms: terms that got axed on the last call to update_terms ( called by do_save)
  def deleted_terms
    @deleted_terms
  end

  #deleted_terms: terms that got added on the last call to update_terms ( called by do_save)
  def added_terms
    @added_terms
  end

  def terms_alpha
    sql =  " select terms.* from terms,terms_users "
    sql += " where terms.id=terms_users.term_id and terms_users.user_id=#{id} "
    sql += " order by terms.text asc"
    Term.find_by_sql(sql)
  end
  
  def future_matches
    sql =  " select matches.* from terms,terms_users,matches,pages "
    sql += " where terms.id=terms_users.term_id and terms_users.user_id=#{id} "
    sql += " and terms.id=matches.term_id and matches.status='notified' and matches.time_status='future'"
    sql += " and matches.page_id=pages.id and pages.status='future' group by matches.id order by date_for_sorting"
    Match.find_by_sql(sql)
  end

  def terms_with_future_matches
    sql =  " select terms.* from terms,terms_users,matches,pages "
    sql += " where terms.id=terms_users.term_id and terms_users.user_id=#{id} "
    sql += " and terms.id=matches.term_id and matches.status='notified' and matches.time_status='future'"
    sql += " and matches.page_id=pages.id and pages.status='future' group by terms.id order by date_for_sorting"
    terms = Term.find_by_sql(sql)
  end

  def terms_with_future_matches_and_no_dates
    sql =  " select terms.* from terms,terms_users,matches,pages "
    sql += " where terms.id=terms_users.term_id and terms_users.user_id=#{id} "
    sql += " and matches.day is null "
    sql += " and terms.id=matches.term_id and matches.status='notified' and matches.time_status='future'"
    sql += " and matches.page_id=pages.id and pages.status='future' group by terms.id order by date_for_sorting"
    terms = Term.find_by_sql(sql)
  end

  def add_term(term,note=nil,note_entity=nil)
    return false if TermsUsers.find_by_term_id_and_user_id(term.id,id)
    clear_terms_cache
    return if !term
    term.num_trackers+=1
    term.aggregate_num_trackers=term.aggregate_num_trackers.to_i+1
    term.save
    tu = TermsUsers.new
    tu.term_id=term.id
    tu.user_id=id
    tu.save    
    Action.user_added_term(metro_code,self,term,note,note_entity)
    return term
  end
  
  def wants_weekly?
    wants_weekly_newsletter=='true'
  end

  def wants_monthly?
    wants_newsletter=='true'
  end

  def self.find_all_needing_newsletter
    sql = <<-SQL
      select * from users 
      where 
      (wants_weekly_newsletter=true and 
        (
          (newsletter_last_sent_on is null) 
          or 
          (newsletter_last_sent_on<adddate(now(),interval -5 day))
        )
      )
      or
      (wants_newsletter=true and 
        (
          (newsletter_last_sent_on is null) 
          or 
          (newsletter_last_sent_on<adddate(now(),interval -25 day))
        )
      )
      group by id
      SQL
    User.find_by_sql(sql)
  end

  def add_term_as_text(term_text,note=nil,note_entity=nil)
    return false if !term_text
    term_text=Term.remove_accents(term_text)
      
    new_term = Term.new
    begin
      new_term.text=term_text
      return if not new_term.validate
      new_term = Term.find_by_text(term_text) # term exists already in db?
    rescue
    end
    if new_term.nil? or new_term.id.nil?
      new_term = Term.new(:text=>term_text) # create this term, link it
      new_term.save
      return unless new_term.id
#      Match.search_and_create_matches(new_term) 
    end
    return add_term(new_term,note,note_entity)
  end
  
  def remove_term(term)
    return if !term
    logger.info("before_save.deleting terms_users with: term_id: #{term.id} user_id: #{id}")
    TermsUsers.delete_all(["term_id=? and user_id=?",term.id,id])
    #c = UserController.new
    #c.expire_term_fragment(term)
    #c    = ActionController::Caching.new    
    #sweeper = TermUsersSweeper.new
    #sweeper.expire_term_fragment(term)
    #ApplicationController.expire_term_fragment(term) # must be explicitly called for delete; sweepers don't 
    # seem to catch the deletes.
  end 

  def normal?
    registration_type=='normal'
  end
  
  def name_chosen?
    name !~ /^anon|none/
  end

  def before_save
    #  logger.info("@terms_as_text: #{@terms_as_text}")
    #  logger.info("before_save.id: #{id}")
    #  update_terms if id # update_terms must be explicitly called for new-user creation
    #get rid of unwanted HTML in message
    about = about.gsub(/<([^>]+)>/," ") if about # get rid of all html
    registration_type="normal" unless name=~/^anon/
  end
  
  
  def do_save
    update_terms
    save
  end

  def after_create
    Action.user_registered(self) 
  end
  
#  attr :terms_as_text
  
  def update_terms(note=nil)
    return if !@terms_as_text
    # get a hash of all the user's current terms, then a hash of the ones in the textarea
    # create two lists from this.
    # one, the new ones that have been added. create new rows for these
    # two, the ones that have been deleted. delete these.
    @all_terms = Array.new
    @added_terms = Array.new
    @deleted_terms = Array.new
    #old_terms = self.terms
    if @terms_as_text
      @terms_as_text.chomp.split(/[\n,]+/).each { |t| #tokenize on CR
        next unless t
        t.strip!
        next if t.empty?
        @all_terms<<t
      }
    end
    
    # get list of terms to add - terms that exist in added_terms but not in old_terms
    th = terms_hash
    all_terms_hash = Hash.new
    @all_terms.each { |term_text|
      all_terms_hash[term_text.downcase]=true
      if not th[term_text]
        add_term_as_text(term_text,note)
        logger.info("added term #{term_text}")  
        @added_terms<<term_text
      end
      }
    
    # get list of terms to delete - terms that exist in old_terms but not all_terms
    terms.each { |term| 
      next unless term
      if not all_terms_hash[term.text.downcase]
        logger.info("deleting a reference to #{term.text}")
        remove_term(term)
        @deleted_terms<<term
      end
      }
  end
end

