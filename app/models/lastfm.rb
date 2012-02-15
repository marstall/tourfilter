require "hpricot"

class Lastfm
  

  def initialize(logger=nil)
    @logger = logger
  end
  
  
  def log (s)
    if @logger!=nil
      @logger.info s 
    else
      puts s
    end
  end

  def verify_username(username)
    return false if get_artist_xml(username).nil?
    return true
  end
=begin
<?xml version="1.0" encoding="UTF-8"?>
  <topartists user="marstall" type="overall">
    <artist rank="1">
      <name>Prefuse 73</name>
      <playcount>232</playcount>
      <mbid>fc61dd75-880b-44ba-9ba9-c7b643d33413</mbid>
      <url>http://www.last.fm/music/Prefuse+73</url>
      <streamable>1</streamable>
      <image size="small">http://userserve-ak.last.fm/serve/34/33236975.png</image>
      <image size="medium">http://userserve-ak.last.fm/serve/64/33236975.png</image>
      <image size="large">http://userserve-ak.last.fm/serve/126/33236975.png</image>
      <image size="extralarge">http://userserve-ak.last.fm/serve/252/33236975.png</image>
      <image size="mega">http://userserve-ak.last.fm/serve/_/33236975/Prefuse+73+prefuse73001.png</image>
    </artist>
=end  

  def import(user)
    username=user.lastfm_username
    xml = get_artist_xml(username)
    names=Array.new
    (xml/ :topartists/ :artist).each {|artist|
      names<<(artist/ :name).inner_html
    }
    names.each{|name|
      user.add_term_as_text(name,"lastfm")
      }
    return names
  end


  def get_artist_xml(username)
    url ="http://ws.audioscrobbler.com/2.0/user/#{username}/topartists.xml"
    text = fetch_url(url)
    if text=~/error/s
      return nil
    end
    xml = Hpricot(text)
  end
  
  def fetch_url(url_text)
    begin
      user_agent = "tourfilter importer - email info@tourfilter.com"
      obj = open(url_text, "User-Agent" => user_agent)
      return obj.read
    rescue => e
  #      handle_exception(e)
      puts "exception loading url '#{url_text}': #{$!}"
      return "error"
    end
  end
  
  
  
  
end