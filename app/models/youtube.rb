require "hpricot"
require 'open-uri'

class Youtube
  DEVELOPER_ID = "AtA4cbv8RDY"

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


  def fetch_url(url_text)
    begin
      user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      obj = open(url_text, "User-Agent" => user_agent)
      obj.read
    rescue => e
#      handle_exception(e)
      puts "exception loading url '#{url_text}': #{$!}"
    end
  end

  def search_youtube(search_string,page,num)
    return unless search_string
    @search_string=search_string
    search_string=URI.encode(search_string)
    _url="http://gdata.youtube.com/feeds/api/videos?&v=2&q=#{search_string}"
    log _url
    text = fetch_url(String(_url))
    xml = Hpricot(text)
    return nil if (xml/ :feed/ :entry).empty?
    return xml
  end

  def find_music_videos(term,page=1,num=20,return_xml=false,title_only=false)
    search_string_1="'#{term}'".gsub " ","+"
#    search_string_3="'#{term}'".gsub " ","+"

    unless title_only
      xml = search_youtube(search_string_1,page,num) 
#      xml = search_youtube(search_string_2,page,num) unless xml
    end
#    xml = search_youtube(search_string_3,page,num) if title_only
    return xml if return_xml
    return extract_data_from_youtube_xml(xml)
  end
  
  def extract_data_from_youtube_xml(xml)
    return unless xml
    data=Array.new
    (xml/ :feed/ :entry).each {|entry|
      data<<{:id=>(entry/ :"yt:videoid"),:thumbnail_url=>(entry/ :"media:thumbnail").first.attributes['url'],:title=>(entry/ :title).inner_html,:url=>(entry/ :"media:player").first.attributes['url']}
    }
    #log data.to_s
    return data
  end
end