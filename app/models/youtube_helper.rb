require "hpricot"
require 'open-uri'

module YoutubeHelper
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
    youtube_developer_key= "AtA4cbv8RDY"
    search_string=URI.encode(search_string)
    _url="http://www.youtube.com/api2_rest?method=youtube.videos.list_by_tag&dev_id=#{youtube_developer_key}&tag=#{search_string}&page=#{page}&per_page=#{num}"
    puts _url
    xml = Hpricot(fetch_url(String(_url)))
    return nil if (xml/:video).empty?
    return xml
  end

  def search_youtube_for_trailers(movie,page=1,num=20,return_xml=false,title_only=false)
    search_string_1="'#{movie.title}' #{movie.year} trailer".gsub " ","+"
    search_string_2="'#{movie.title}' trailer".gsub " ","+" 
    search_string_3="'#{movie.title}'".gsub " ","+"

    unless title_only
      xml = search_youtube(search_string_1,page,num) 
      xml = search_youtube(search_string_2,page,num) unless xml
    end
    xml = search_youtube(search_string_3,page,num) if title_only
    return xml if return_xml
    return extract_ids_from_youtube_xml(xml)
  end
  
  def extract_ids_from_youtube_xml(xml)
    return unless xml
    ids=Array.new
    (xml/:video).each {|user|
      id = (user/:id).inner_html if (user/:id)
      title = (user/:title).inner_html if (user/:title)
      if id
        puts "#{id}: #{title}"
        ids<<id
      end
    }
    return ids.first
  end
end