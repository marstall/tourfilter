require "../app/models/page.rb" 
require "../app/models/place.rb"
require "../app/models/match.rb"
require "../app/models/term.rb"
require "../app/models/user.rb"

class NewsletterMailer < ActionMailer::Base
  include CalendarModule
  include QuickAuthModule
  include ProfileModule
  
  helper :application 
  @@popular_matches=nil
  @@sponsor_matches=nil
  @@uncollated_popular_matches=nil
  
  def generate_subject(user_days,user_matches,related_matches,popular_matches)
    _matches=Array.new
    user_days.each{|day|
      user_matches[day].each{|match|
        _matches<<match
        }
      }
    if _matches
      _matches.sort!{|x,y| x.id <=> y.id}
      if _matches.size>2
        subject_matches=_matches[0..1] 
      else
        subject_matches=_matches
      end
    end
    if related_matches
      if _matches.empty?
        _matches = related_matches 
      elsif _matches.size<=3
        _matches+=related_matches
      end
    end
    _matches||=Array.new
    if popular_matches
      if _matches.empty?
        _matches = popular_matches 
      elsif _matches.size<=3
        _matches+=popular_matches
      end
    end
    _matches||=Array.new
    #subject_matches = popular_matches if subject_matches.size==0
    @subject=""
    used_terms=Hash.new
    k=0
    if _matches and not _matches.empty?
      _matches.each_with_index{|match,i|
          next if used_terms[match.term.text]
          break if k>2
          k+=1
           @subject+=", " if (i!=0)
           used_terms[match.term.text]=true
          @subject+=match.term.text.downcase
        }
      @subject+=", more"
    else
      @subject = "upcoming shows"
    end
    @subject
  end
  
  def newsletter(metro_code,user,sent_at = Time.now)
      metro = Metro.find_by_code(metro_code)
      @body["metro"] = metro.name rescue metro_code
      start_timer ("newsletter_mailer.newsletter")
      content_type "text/html"
      @periodicity,@period="weekly","week"
      @periodicity,@period="monthly","month" if user.wants_monthly?
      @body["user"] = user
      @body["metro_code"] = metro_code
      @body["periodicity"] = @periodicity
      @body["period"] = @period
      @recipients=user.email_address
      #@bcc='tourfilter.admin@gmail.com'
      @from       = "tourfilter #{metro.name.downcase} newsletter <info@tourfilter.com>"
      @sent_on    = sent_at
      start_timer("user_matches")
      body["user_days"],body["user_matches"] = setup_calendar(user,nil,360,0)
      end_timer("user_matches")

      user_days = body['user_days']
      user_matches = body['user_matches']
      terms_with_tickets=Array.new
      start_timer("friend_matches")
      friend_matches=Match.recommended_matches_within_n_days_for_user(180,user,"date_for_sorting asc",25)
      body["recommended_days"],body["recommended_matches"] = matches2calendar(friend_matches)
      end_timer("friend_matches")
      
      start_timer("related_matches")
      related_matches=Match.related_matches_for_user(user,25)
      body["related_days"],body["related_matches"] = matches2calendar(related_matches)
      end_timer("related_matches")

      start_timer("popular_matches")
      if @@uncollated_popular_matches.nil?
        puts "calculating popular matches"
        @@uncollated_popular_matches = Match.popular_upcoming_matches_by_source("any",num_days=90,num=25)
        @@popular_days,@@popular_matches = matches2calendar(@@uncollated_popular_matches)
      end
      body["popular_days"],body["popular_matches"] = @@popular_days,@@popular_matches
      end_timer("popular_matches")

      start_timer("sponsor_matches")
      end_timer("sponsor_matches")

	    recommenders=user.recommenders
	    recommender_ids=Hash.new
	    recommenders.each{|recommender|recommender_ids[recommender.id]=true}
	    body["recommender_ids"]=recommender_ids
      body["auth_token"] =     quick_auth_token(user)
      @headers    = {}

      @subject = generate_subject(body['user_days'],body['user_matches'],related_matches,@@uncollated_popular_matches)

      end_timer ("newsletter_mailer.newsletter")
  end
end
