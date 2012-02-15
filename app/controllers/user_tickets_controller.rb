=begin
CREATE TABLE `user_ticket_offers` (
  `id` int(11) NOT NULL auto_increment,
  `uid` char(64) default NULL,
  `match_id` int(11) default NULL,
  `price` float(11,2) default NULL,
  `quantity` int(11) default NULL,
  `section` varchar(32) default NULL,
  `row` varchar(4) default NULL,
  `created_at` datetime default NULL,
  `updated_at` datetime default NULL,
  `subject` text default NULL,
  `body` text default NULL,
  PRIMARY KEY  (`id`),
  KEY `match_id` (`match_id`)
)
=end

class UserTicketsController < ApplicationController

  def auto_complete_for_match_description
    @matches = Match.find_by_description_fragment(params[:match][:description])
    if @matches
      render :inline => '<%=content_tag(:ul, @matches.map { |match| content_tag(:li, h(match.dropdown_description)) }) %>' 
    else
      render :inline => ''
    end
  end

  def sell_tickets
    use_full_width_footer
    return if not must_be_known_user
  end

  def flag_uto
    must_be_known_user
    id = params[:id]
    uto = UserTicketOffer.find(id)
    if uto
      session[:num_flagged]||=0
      session[:num_flagged]+=1
      if session[:num_flagged]>10
        error = "We limit the number of ticket postings that can be flagged in a given period of time; you've exceeded that limit. Apologies if this limit is unwarranted in your case."
      else
        uto.flag_count+=1
        uto.save
        session["flagged_#{uto.id}"]=true
        notice = "You have successfully flagged the posting. An admin has been notified and will take a look shortly"
        FlagMatchMailer.deliver_flag_uto(self,uto,@youser)
      end
    else
      error = "Unrecognized user-ticket-offer-id, nothing was flagged."
    end
    flash[:notice]=notice if notice
    flash[:error]=error if error
    redirect_to "/have_want_tickets"
    expire_term_fragment(uto.match.term) 
  end
  
  
  def unflag_uto
    must_be_admin
    id = params[:id]
    uto = UserTicketOffer.find(id)
    if uto
      if is_admin?
        uto.flag_count=0
        uto.save
        notice = "You have successfully unflagged the posting. "
        else
        error = "You don't have permission to unflag that posting!"
      end
    else
      error = "Unrecognized user-ticket-offer-id, nothing was unflagged."
    end
    flash[:notice]=notice if notice
    flash[:error]=error if error
    redirect_to "/have_want_tickets?flagged=true"
    expire_term_fragment(uto.match.term) 
  end

  def delete_uto
    must_be_known_user
    id = params[:id]
    uto = UserTicketOffer.find(id)
    if uto
      if is_admin? or uto.user_id==@youser.id
        UserTicketOffer.delete(id)
        notice = "You have successfully deleted the posting."
        else
        error = "You don't have permission to delete that posting!"
      end
    else
      error = "Unrecognized user-ticket-offer-id, nothing was deleted."
    end
    flash[:notice]=notice if notice
    flash[:error]=error if error
    redirect_to "/have_want_tickets"
    expire_term_fragment(uto.match.term) 
  end
  
  def user_tickets2
    user_tickets
  end
  
  def user_tickets
    use_full_width_footer
    order2=:date
    if params[:flagged]
      @match_descriptions,@match_description_utos = UserTicketOffer.find_active_flagged(order2,@youser_id)
      return
    end
    if params[:own_only]
      @match_descriptions,@match_description_utos = UserTicketOffer.find_active_by_user_id(order2,@youser_id)
      return
    end
    if params[:query]
      @match_descriptions,@match_description_utos = UserTicketOffer.find_active_by_query(order2,params[:query])
    else
      @match_descriptions,@match_description_utos = UserTicketOffer.find_all_active_grouped(order2)
    end
    render
  end
  
  def validate
    @errors=Array.new
    @errors<<"must enter a (longer) about the tickets" unless params[:body] and params[:body].strip.size>3
    @errors<<"must enter a (longer) who, when, where" unless params[:match][:description] and params[:match][:description].strip.size>3
    @errors<<"the 'about the tickets' section is too long" unless params[:body] and params[:body].strip.size<2048
    @errors<<"the 'who, when, where' section is too long" unless params[:match][:description] and params[:match][:description].strip.size<255
#    @errors<<"must select a metro" unless params[:object][:metro_code] and params[:object][:metro_code].strip.size>3
    return @errors.empty?
  end

  def handler
    puts "handler"
    unless validate
      render(:layout=>false)
      return
    end
    
    if params[:submit]=='cancel'
      render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
      return
    end
    
    match_description = params[:match][:description]

    uto = UserTicketOffer.new
    match = Match.find_by_description(match_description)
    uto.match_id = match ? match.id : nil
    uto.match_description = match_description
    uto.body = params[:body]
    uto.user_id = @youser_id
    uto.save
    flash[:notice] = "Your tickets have been posted! They should appear shortly. You can <span class='underline'><a href= '/#{@metro_code}/have_want_tickets?own_only=true'>manage your submitted tickets</a>.</span>"
    render(:inline=>"<script>location.href='/#{@metro_code}/have_want_tickets';</script>",:layout=>false)
    expire_term_fragment(match.term) if match
  end

  def handler_
    if params[:button]=~/Done/
      flash[:notice]="Registration complete!"
      render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
      return
    end
    @youser.update_attributes(params[:youser])
    @youser.registration_type="normal" and @youser.save if @youser.name!="none"
    if @youser.errors.empty?
      flash[:notice]="You have successfully changed your settings!" 
      flash[:notice]="Your new profile has been created. Registration complete!" if params[:prior_referer]=~/welcome/
      ChangedSettingsMailer::deliver_changed_settings(@youser)
      expire_youser_page
      render(:inline=>"<script>location.href='/#{@metro_code}';</script>",:layout=>false)
      return false
    else
      render(:layout => false)
    end
  end  

end