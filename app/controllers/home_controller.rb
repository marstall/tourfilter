class HomeController < ApplicationController
  before_filter :must_be_known_user_no_message, :except => 'about'
  #caches_page :index

  def add
    @success=false
    term = params[:term]
    if term=="search for/add a band"
      render(:layout =>false)
      return
    end
    begin
      if term and @youser.add_term_as_text(params[:term]) 
        expire_term_fragment(term) 
        @message = "#{term} added!"
        @success=true
      end
    rescue
#      @message=$!
    end
    @message = "You already track '#{term}'!" if not @success
    render(:layout =>false)
  end
  
  def search
    @term_text=request.raw_post
    @term_text= @term_text.chomp.split("&_=").first if @term_text            
    if @term_text&&@term_text.size<3
      render(:layout=>false)
      return
    end
    # find other users tracking this term
    begin
      term=nil
      term = user_terms_texts[term_text] if @youser # first check if it is is in the hash, preloaded
      term = Term.find_by_text(term_text) if !term
      match = term.future_matches(1).first
      page=match.page if match
    rescue
      @hit_page = Page.find(:first, :conditions => [ "status='future' and body like ?", 
                            "% #{@term_text} %"]) 
    end
    render(:layout =>false)
  end
  
  def index
    @matched_terms=@youser.terms_with_future_matches
    matched_term_ids = Hash.new
    @matched_terms.each{|term| matched_term_ids[term.id]=true}
    @unmatched_terms = Array.new
    all_terms = @youser.terms
    #@unmatched terms is all_terms minus @matched_terms    
    all_terms.each {|term| @unmatched_terms<<term if not matched_term_ids[term.id]}
    @unmatched_terms.sort! {|x,y| x.text<=>y.text}
  end
end
