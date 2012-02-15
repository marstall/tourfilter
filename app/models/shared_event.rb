include GeoKit::Geocoders
require 'icalendar'

class SharedEvent < ActiveRecord::Base
  acts_as_mappable :lat_column_name=>:metro_lat,
                   :lng_column_name=>:metro_lng
  belongs_to :venue
  establish_connection "shared" unless $mode=="daemon"

  # if there is a space
=begin
  if summary.index(' ') 
    # get the final word
    words = summary.scan(/w+/)
    if words 
      if words.size>1
        if metro_name_hash[words.last]
          metro_code= metro_name_hash[words.last] 
          summary=summary[0..summary.index(words.last)].strip
        elsif words.size>2
          potential_city_name=words[words.size-2]+" "+words[word.size-1]
          if metro_name_hash[potential_city_name]
            metro_code=metro_name_hash[potential_city_name] 
            summary=summary[0..summary.index(potential_city_name)].strip
          end
        end
      end
    end
  end
=end
  def imported_events
#    ImportedEvent.new.search(summary)
  ImportedEvent.find_by_term_and_date(summary,date)
  end

  def self.find_all_unique(metro_code=nil)
    if metro_code
      puts "metro_code: #{metro_code}"
      find_by_sql("select * from shared_events where metro_code='#{metro_code}' group by summary order by summary")
    else
      find_by_sql("select * from shared_events group by summary order by summary")
    end
  end

  def url_summary
    t = summary.downcase.strip # make it all lowercase
    t=t.gsub(/\s/,"_") #substitute underscores for spaces
  end

def self.search_with_multiple_terms(terms,metro_code=nil,num=100)
  sql =  " select * from shared_events "
  token = "','"
  sql += " where summary in ('#{terms.join(token)}') "
  sql += " and metro_code='#{metro_code}' " if metro_code and not metro_code.strip.empty?
  sql += " order by date asc, summary limit #{num} "
  SharedEvent.find_by_sql(sql)
end

def self.find_all_for_metro(metro_code,num=200)
  sql =  " select * from shared_events "
  sql += " where metro_code= ? " if metro_code and not metro_code.strip.empty?
  sql += " order by date asc, summary limit ? "
  params=Array.new
  params<<metro_code if metro_code and not metro_code.strip.empty?
  params<<num
  SharedEvent.find_by_sql([sql]+params)
end

def self.search_nearby(summary,lat,lng,distance=400,num=5)
    find(:all, :origin => [lat,lng],:within=>distance,:conditions=>"summary like '%#{summary}%'",:order=>"distance,date asc",:limit=>num)
end

def self.search(shared_event_hash,num=100)
  summaries = shared_event_hash[:summary].strip
  metro_codes = shared_event_hash[:metro_codes]
  metros=Metro.find_all_active
  metro_name_hash=Hash.new
  metro_code=nil
  metros.each{|metro|
    metro_name_hash[metro.name.downcase]=metro.code
  }
  sql =  " select * from shared_events "
  all=term_only=metro_only=place_only=false
  tokens = summaries.scan(/[^,]+/)
  params=Array.new
  first=true
  tokens.each{|summary|
    all=true if summary=~/all:\d+/
    place_only=true if summary=~/^club:/
    metro_only=true if summary=~/^metro:/
    term_only=true if summary=~/^band:/ or tokens.size>1
    exact_match=true if tokens.size>1
    #puts "metro_only: #{metro_only}"
    summary.sub! /^\w+:/,""
    summary.strip!
    next if summary=="the"
    summary.sub! /^the /,""
    num=Integer(summary) if all
    next if summary.blank?
    participle="or"
    participle="where" if first
    if term_only
      num_subs=1
      if exact_match
        sql += " #{participle} summary = ? "
      else
        sql += " #{participle} summary like ? "
      end
    elsif place_only
      num_subs=1
      sql += " #{participle}  location like ? "
    elsif metro_only
      num_subs=2
      sql += " #{participle}  (metro_code like ? "
      sql += " or metro_name like ? )"
    elsif all
      num_subs=0
    else # check all
      num_subs=4
      sql += " #{participle}  (summary like ? "
      sql += " or location like ? "
      sql += " or metro_code like ? "
      sql += " or metro_name like ? )"
    end
    search_expression=String.new
    if exact_match
      search_expression = summary
    else
      search_expression="%" if summary.size>1
      search_expression+="#{summary}%"
    end
    1.upto(num_subs) {
      params<<search_expression
    } 
    first=false
  }
  if metro_codes and not metro_codes.empty?
    sql += " and metro_code in ('#{metro_codes.join('\',\'')}') "
  end
  sql += " group by date "
#  if metro_codes and not metro_codes.empty?
#    sql += " order by distance limit ?"
#  else
    sql += " order by date asc, summary limit ? "
#  end
  params<<num
#  puts sql
  shared_events = SharedEvent.find_by_sql([sql]+params)
  return normalize_shared_events(shared_events) # get rid of "the" dupes
end

def self.normalize_shared_events(shared_events)
  return unless shared_events
  #hashify
  hash = Hash.new
  ret_shared_events=Array.new
  shared_events.each{|shared_event|
    term_text = Term.normalize_text(shared_event.summary)
    ret_shared_events<<shared_event if hash[term_text]!=shared_event.date
    hash[term_text]=shared_event.date
  }
  ret_shared_events
end

=begin
BEGIN:VEVENT
URL:<%=shared_event.url%>
DTSTART:<%=shared_event.ical_date%>
DTEND:<%=shared_event.ical_date%>
UID:<%=shared_event.uid%>
DESCRIPTION: <%=shared_event.description%>
SUMMARY:<%=shared_event.summary%>
DTSTAMP:<%=DateTime.now%>
SEQ:<%=i%>
LOCATION:<%=shared_event.metro_name%>
END:VEVENT
=end
def to_ical_event(i)
  event = Icalendar::Event.new
  event.timestamp=DateTime.now
  mod_date=DateTime.new(date.year,date.month,date.day,17)
  event.start=mod_date
  event.end=mod_date
  event.summary=summary
  event.location=location
  event.description=description
  event.url=url
  event.uid=uid
  event.seq=i
  event
end

def to_json(*a)
  {
    "tourfilter events" => [ summary,location,metro_name,metro_state,metro_lat,metro_lng,date,url,uid ]
  }.to_json(*a)
end
  
def hacked_to_json
"{\"tourfilter events\":[\"#{summary}\",\"#{location}\",\"#{metro_name}\",\"#{metro_state}\",#{metro_lat},#{metro_lng},\"#{date}\",\"#{url}\",#{uid}]}"
end
  
def render_as_ical_event(i)
  to_ical_event(i).to_ical 
end

def parsed_ticket_json
  JSON.parse(self.ticket_json) 
end

end
