# daemon for tourfilter which:
#   1. loads all urls from the page table
#   2. crawls the value of these urls and puts them into the body column of the page table
#   3. for each user, performs each saved search on all pages in the appropriate metros
#   4. for each match, creates a record in the match table with status of "new"
#   5. when all is complete, for each user, find all new matches, concatenated a report of them
#       and send the report in an email to the user's on-file email address
require "rubygems"
require "net/http"
require 'open-uri'
require_gem "activerecord"
require "../app/models/page.rb"
require "../app/models/place.rb"

place_id = ARGV[0]
def fetch_url(url_text)
  user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
  obj = open(url_text, "User-Agent" => user_agent)
  obj.read
end
#def fetch_url(url_text)
#  url = URI.parse(url_text)
#  req = Net::HTTP::Get.new(url.path)
#  res = Net::HTTP.start(url.host, url.port) {|http|
#    http.request(req)
#  }
#  res.body
#end
puts "read to go, hit any key to continue"
gets
puts "establishing connection ..."
ActiveRecord::Base.establish_connection(:adapter=>"mysql",:host=>"localhost",
        :database=> "tourfilter_development")

pages=nil
puts "connection established, hit any key to do the rest"
gets
puts "getting all pages ..."
if (place_id.nil?)
  pages = Page.find(:all) if place_id.nil?
else
  place = Place.find(place_id)
  pages= place.pages if !place.nil?
end
puts "done"
gets "hit any key to quit"

