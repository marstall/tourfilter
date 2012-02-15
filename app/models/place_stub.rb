class PlaceStub
  attr_accessor :url,:name,:time_type,:num_shows
  def url_name
    name.downcase.gsub(/\s/,"_")
  end
  
  def process_urls
  end

  def short_name
    short_name=name.gsub(/(the|and|a|of|in)\s/,"")
    words = short_name.scan(/[\w']+/)
    if words and words.length>2
      return words[0]+" "+words[1]+"*"
    else
      return "#{short_name}*"
    end
  end

  def process_images
  end
end
