require 'hpricot'

module Parser

	def parse(place)
#	  puts "#{self.class.name} parser"
		place.future_pages.each{|page|
#		  puts "parsing #{page.url} ... "
      new_showings=parse_page(page)
#      showings+=new_showings if new_showings
	  }
	end

  def clean(s)
    return "" if s.nil?
    s.gsub(/<([^>]+)>/,"").strip
  end

  def clean_url(url)
    # get rid of anchor section
    url = url.gsub(/\#.+?$/,"")
    return url
  end

  def fetch_url(url_text)
    begin
      user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      obj = open(clean_url(url_text), "User-Agent" => user_agent)
      obj.read
    rescue Exception
      puts "error fetching url: #{$!}"
      puts "continuing ... "
    end
  end
  
  def fetch_hpricot(url)
    html=fetch_url(url)
#    puts "HTML: #{html}"
    return nil unless html
    Hpricot(html)
  end
  
  def initial_capsify(text)
    ret = ""
    text.each(" "){|word|
      ret+=" "
      ret+=word.capitalize
    }
    ret.strip
  end
  

end