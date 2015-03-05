class RedirectController < ApplicationController  
  
  # passed:
  # type = "ticket", "info", etc.
  # url
  # referer
  # term_text
  # ticket_source = "user","ticketmaster","stubhub"
  # level = "primary", "secondary"
  # link_source = "web","mail","badge"
  # page = "band", "user", "me","match_mail" etc.
  # page_section = "main_show","similar","popular"
  
  
  # derived:
  # metro_code 
  # youser_id

  def normal_mail_ticket_redirect
    ticket_redirect("normal_match_mail")
  end

  def onsale_mail_ticket_redirect
    ticket_redirect("onsale_match_mail")
  end

  def monthly_newsletter_ticket_redirect
    ticket_redirect("monthly_mail")
  end

  def weekly_newsletter_ticket_redirect
    ticket_redirect("weekly_mail")
  end
  
  def ticket_preredirect
    url = request.path
    url +="?lp=1"
    #render(:inline=>url)
    render(:inline=>"<script>document.location.href='#{url};'</script>")
  end
  
  def ticket_redirect(name)
    if not params[:lp]
      ticket_preredirect
      return
    end
    match = Match.find(params[:id])
    if match.nil?
      flash[:error]='error: unknown url'
      redirect_to '/'
      return
    end
    ec = ExternalClick.new
    ec.url=match.url_ticketmaster_preferred
    ec.link_source='mail'
    ec.page_type=name
    referer = log_referer(request,cookies,name,match)
    log_external_click(ec,referer.id)
    redirect_to ec.url
    #render(:inline=>ec)
  end

    
  def preredirect
    ec_params= params[:ec]
    url = request.path
    url +="?lp=1"
    ec_params.each_key{|key,i|
        url+=URI::encode("&ec[#{key}]=#{ec_params[key]}")
      }
    render(:inline=>"<script>document.location.href='#{url};'</script>")
  end
  
  def redirect
    #if not params[:lp]
    #  preredirect
    #  return
    #end
    logger.info("params[:ec]: #{params[:ec]}")
    ec = ExternalClick.new(params[:ec])
    log_external_click(ec)
#    render(:inline=>params[:ec].inspect)
    logger.info("redirecting to #{ec.url}")
    redirect_to ec.url
  end

end