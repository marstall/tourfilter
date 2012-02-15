class FlagController < ApplicationController  

  before_filter :must_have_manage_match_privs, :except=>"flag_match"
  def flag_match
    id=params[:id]
    @match=Match.find(id)
    if not @youser
      flash[:error]="you must be logged in to do that!"
      redirect_to "/#{@match.term.url_text}"
      return
    end
#    begin
      if request.env['HTTP_REFERER'] !~ /.+?tourfilter.+?#{@match.term.url_text}$/
        #flash[:error]="there was an error. flagging didn't work!"
        redirect_to "/#{@match.term.url_text}"
        return
      end
      @match.flag_count+=1
      @match.record_edit(@youser,"flag")
      @match.save
      invalidate_caches_for_match_comments(@match)
      expire_term_fragment(@match.term)
      FlagMatchMailer::deliver_flag_event(self,@match,@youser,"match flagged")
      #flash[:notice]="you successfully flagged this show!"
      redirect_to "/#{@match.term.url_text}"
#    rescue
#      @error=true
#    end
  end

  def change_match_date
      id=params[:id]
      @match=Match.find(id)
      day=params[:day]
      month=params[:month]
      year=params[:year]
      if not (day and month and year)
        flash[:error]="you must enter a day, month and year"
        redirect_to "/#{@match.term.url_text}"
        return
      end
      begin
        new_date=Date.new(Integer(year),Integer(month),Integer(day))
        if new_date.day==@match.day and new_date.month==@match.month and new_date.year==@match.year
          #flash[:error]="You didn't change the date!"
          redirect_to "/#{@match.term.url_text}"
          return
        end
        @match.date_for_sorting=new_date
        @match.day=day
        @match.month=month
        @match.year=year
        @match.flag_count=0
        @match.record_edit(@youser,"new_date",new_date)
        @match.save
        invalidate_caches_for_match_comments(@match)
        expire_term_fragment(@match.term)
      rescue =>e
        flash[:error]="There was an error (#{e})- perhaps an invalidate date (#{month}/#{day}/#{year}) ?"
        redirect_to "/#{@match.term.url_text}"
        return
      end
      
      # now send the message
      CorrectionMailer::deliver_correction(self,@match)
      flash[:notice]="The date was successfully updated and correction mails were sent out!"
      redirect_to "/#{@match.term.url_text}"

  end

  def unflag_match
    begin
      id=params[:id]
      @match=Match.find(id)
      @match.flag_count=0
      @match.record_edit(@youser,"unflag")
      @match.save
      invalidate_caches_for_match_comments(@match)
      expire_term_fragment(@match.term)
      FlagMatchMailer::deliver_flag_event(self,@match,@youser,"match unflagged")
      #flash[:notice]="you successfully unflagged this show!"
      redirect_to "/#{@match.term.url_text}"
    rescue
      @error=true
    end
  end
  def invalidate_term_matches
    id = params[:id]
    term= Term.find(id)
    matches = term.future_matches||[]
    matches.each{|match|
      match.status='invalid'
      match.record_edit(@youser,"invalidation")
      match.save
      invalidate_caches_for_match_comments(match)
      expire_term_fragment(term)
      FlagMatchMailer::deliver_flag_event(self,match,@youser,"match invalidated")
      flash[:notice]="you successfully invalidated #{matches.size} matches for term '#{term.text}'!"
    }
    redirect_to request.env['HTTP_REFERER']
  end

  def invalidate_match
    begin
      id=params[:id]
      @match=Match.find(id)
      @match.status='invalid'
      @match.record_edit(@youser,"invalidation")
      @match.save
      expire_term_fragment(@match.term)
      FlagMatchMailer::deliver_flag_event(self,@match,@youser,"match invalidated")
      flash[:notice]="you successfully invalidated this show!"
      redirect_to "/#{@match.term.url_text}"
    rescue
      @error=true
    end
  end


  
  def flag_place
  end
end