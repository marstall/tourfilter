class RelatedTerm < ActiveRecord::Base

  establish_connection "shared_#{ENV['RAILS_ENV']}" #unless $mode=="daemon"

  belongs_to :term
  
  def url_text
    t =related_term_text.downcase # make it all lowercase
    t=t.gsub(/\s/,"_") #substitute underscores for spaces
  end

  def related_term
    Term.find_by_text(related_term_text)
  end
  
  def default?
    term_text=='^default^'||term_text=='popular'||term_text.strip.empty?
  end

  def calculate_score
    self.score = self.count+(100000*played_with_count)
  end

  def based_on_played_with
    played_with_count>0
  end
  
  def self.random_set(threshhold=1000,num=10,used_terms=[])
    terms_hash=Hash.new
    used_terms.each{|term|
      if term.is_a? String
        terms_hash[term]=true
      else
        terms_hash[term.text]=true
      end
    }
    shared_terms= SharedTerm.random_set(threshhold,num)
    rts = []
    shared_terms.each{|shared_term|
      rt = RelatedTerm.new
      rt.id=shared_term.id
      rt.related_term_text=shared_term.text
      rt.term_text='^default^'
      rts<<rt if not terms_hash[shared_term.text]
    }
    rts
  end

  def self.defaults
    RelatedTerm.find_all_by_term_text("^default^",:order=>'term_text desc')
  end

  def term_text
    return 'popular' if super=='^default^'
    super
  end
end