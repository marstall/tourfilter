module RedirectModule

  def encode(s)
    return "" if s.nil?
    s = URI::encode(s)
    s.gsub! "&", "%26"
    s.gsub! "?", "%3F"
    s.gsub! "+", "%2B"
    s
  end
  
  
  # good hash keys to use: page_type,page_section,term_text
  def evented_redirect_url(url,external_link_hash={},extra_hash={},ticket_hash={},options={},relative_url=true)
    external_link_hash||=Hash.new
    extra_hash||=Hash.new
    ticket_hash||=Hash.new
    hash=external_link_hash+ticket_hash+extra_hash
    hash['url']||=url
    params="?ec[url]=#{encode(hash['url'])}&"
    hash.each_key{|key|
      next if key=='url'
      params+="ec[#{key}]=#{encode(hash[key])}&"
    }
    if relative_url==false
      url="http://www.tourfilter.com/" 
    else
      url="/"
    end
    url+="r/#{params}"
    return url
  end
end