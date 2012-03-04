if $mode =~ /daemon/
  require "../app/models/page.rb"
  require "../app/models/place.rb"
  require "../app/models/match.rb"
  require "../app/models/term.rb"
  require "../app/models/user.rb"
end

class MatchMailer < ActionMailer::Base
  helper :application 

=begin
content_type "text/text"
ticket_urls,price_low,price_high = match.ticket_urls
body['price_low']=price_low
if price_low and price_low.to_i>0
  plus = ""
  plus="+" if price_high>price_low
  @body["tickets_available"]=true
  price_string = " - buy tix here for $#{Integer(price_low).to_s}#{plus}"
else
  price_string=""
  @body["tickets_available"]=false
end
=end

  def onsale_match(metro_code,match,sent_at = Time.now)
    time=""
    begin
      hour=DateTime.new(match.onsale_date).hour.to_i
      minute=DateTime.new(match.onsale_date).minute.to_i
      ampm= hour>=12 ? "PM" : "AM"
      time=hour.to_s
      time+=":#{minute.to_s}" unless minute==0
      time = "#{time} #{ampm}"
    rescue
    end
    @subject    = "#{match.term.text.downcase} tickets go on sale TODAY #{time}!"
    @body["match"] = match
    @body["metro_code"] = metro_code
    @bcc=""
	users = match.term.users.uniq{|user|user.email_address }  
       users.each { |user| 
      @bcc+=(user.email_address+",")
      }
    
    @bcc=@bcc.chomp(",") # remove trailing comma
    puts "bcc: #{@bcc}"
    @from       = "#{metro_code}.tourfilter <#{metro_code}@tourfilter.com>"
    @sent_on    = sent_at
    #      body["related_matches"],body["featured_matches"] = Match.featured_matches(match.term.text,20)
    @headers    = {}
  end

  def match(metro_code,match,sent_at = Time.now)
      @subject    = "#{match.term.text.downcase.strip} show"
      @body["match"] = match
      @body["metro_code"] = metro_code
      @bcc=""
      users = match.term.users
      return if users.empty?
        users = match.term.users.uniq{|user|user.email_address}
       users.each { |user|          
       @bcc+=(user.email_address+",")
        }
      @bcc=@bcc.chomp(",") # remove trailing comma
      puts "bcc: #{@bcc}"
      @from       = "#{metro_code}.tourfilter <#{metro_code}@tourfilter.com>"
      @sent_on    = sent_at
#      body["related_matches"],body["featured_matches"] = Match.featured_matches(match.term.text,20)
      @headers    = {}
  end
end
