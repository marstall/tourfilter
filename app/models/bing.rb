require 'rubygems'
require 'mechanize'
require 'json'

class Bing
  def initialize(logger)
    @logger = logger
  end
  
  
  def log (s)
    if @logger!=nil
      @logger.info s 
    else
      puts s
    end
  end

  include UrlFetcher
  API_KEY="5571ECA1532D0128C0E7A4BB28EF75031381A335"  

 def bing_url(term_text,sources,num=1,offset=0)
   "http://api.bing.net/json.aspx?AppId=#{API_KEY}&Market=en-US&Query=#{term_text.gsub(' ','+')}&Sources=#{sources}&Web.Count=#{num}&Web.offset=#{offset}"
 end

 def bing_photo_url(term_text,num=1)
 end

 def bing_web_url(term_text,num=1)
   bing_url(term_text,'web',num)
 end

 def photos_for_term(term_text,num=1)
   begin
     term_text="#{term_text}+band+filterui:aspect-wide+filterui:photo-photo"
     log("+++term_text:#{term_text}")
     json = fetch_bing_json(term_text,'image',num) rescue ""
     if json
       results = json['SearchResponse']['Image']['Results'] 
       return results[0..num-1] if num>0
     end
   rescue
   end
   return []
 end

 def fetch_bing_json(term_text,sources,num)
   url = bing_url(term_text,sources,num+5)
   body,cached = fetch_url(url)
   JSON.parse(body)
 end

 def web_results_for_term(term_text,num=1)
   term_text="#{term_text}+band"
   json = fetch_bing_json(term_text,'web',num)
   results = json['SearchResponse']['Web']['Results']
   return results[0..num-1] if num>0
   return []
 end

end


=begin
photo json:

{"SearchResponse":

{"Version":"2.1","Query":

{"SearchTerms":"neko case"},"Image":

{"Total":60200,"Offset":0,"Results":[

{
  "Title":"Matador Records | News October 2002",
  "MediaUrl":"http:\/\/www.matadorrecords.com\/images\/neko_case\/NekoCase007_small.jpg",
  "Url":"http:\/\/www.matadorrecords.com\/news\/2002-10.html",
  "DisplayUrl":"http:\/\/www.matadorrecords.com\/news\/2002-10.html",
  "Width":270,"Height":350,
  "FileSize":14705,
  "ContentType":"image\/jpeg",
  "Thumbnail":
  
{
    "Url":"http:\/\/ts1.images.live.com\/images\/thumbnail.aspx?q=758419292780&id=4e5e3de50d3df519c304f86b79be2fdf",
    "ContentType":"image\/jpeg","Width":123,"Height":160,"FileSize":3926
  }
}
=end

=begin
web json:

{"SearchResponse":
{"Version":"2.1","Query":
{"SearchTerms":"a.c. newman"},"Web":
{"Total":1660000,"Offset":0,"Results":[
{
  "Title":"Carl Newman - Wikipedia, the free encyclopedia",
  "Description":"Allan Carl Newman (born April 14, 1968) is a Canadian musician and songwriter. He was a member of the indie rock bands Superconductor and Zumpano in the 1990s.",
  "Url":"http:\/\/en.wikipedia.org\/wiki\/A.C._Newman","CacheUrl":"http:\/\/cc.bingj.com\/cache.aspx?q=%22a+c%22+newman&d=76251120142695&mkt=en-US&w=6b64e1ed,c8286594",
  "DisplayUrl":"en.wikipedia.org\/wiki\/A.C._Newman","DateTime":"2009-05-26T07:24:26Z"}]
}}}
=end