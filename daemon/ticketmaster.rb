require "../app/models/imported_events.rb"
require "../app/models/shared_events.rb"

def Ticketmaster
  def self.find_valid_urls
    # find valid urls - only do 
    # fill up locations table with valid ticketmaster locations/urls
    base_url="http://www.ticketmaster.com/venue/"
    range=[0..300000]
    range.each{||
  end

  def self.crawl
    # fetch each url and parse out times and dates
  end
end