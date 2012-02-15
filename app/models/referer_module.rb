module RefererModule
  
  def extract_keywords(url)
    keywords=Array.new
    if url=~/google/
      engine='google'
      tokens = URI::decode(url).split(/[?&]/)
      tokens[1..tokens.size].each{|t|
          name_val = t.split("=")
          if name_val[0]=='q'
            keywords=name_val[1].split("+")
            break
          end
        }
    else
      return nil,nil,nil,nil,nil
    end
    keywords_without_metro=Array.new
    metro_code=nil
    skip=false
    keywords.each_with_index{|keyword,i|
      if skip
        skip=false
        next
      end
      keyword2= keyword+" "+ keywords[i+1] if i+1<keywords.size
        keyword.strip.downcase!
        if @metros[keyword]
          metro_code=keyword
        elsif i+1<keywords.size and @metros[keyword2]
          metro_code=keyword2
          skip=true
        else
          keywords_without_metro<<keyword
        end
      }
    return engine,keywords.join(" "),metro_code,keywords_without_metro.join(" ")
  end
  
  def log_match_for_referer(match)
    return unless match
#    cookies[:match_id]=match.id.to_s
    session[:match_id]=match.id
  end

  def log_referer(request,cookies,forced_referer=nil,match=nil)
    @metros = Metro.code_and_name_hash
    referer=forced_referer||request.env['HTTP_REFERER']
#    referer="http://www.google.com/search?q=lalah+hathaway+in+dc&ie=UTF-8&oe=UTF-8&hl=en&client=safari"
    unless forced_referer
      return unless referer and referer.strip=~/^http/ and referer !~ /^http:\/\/.+?\.tourfilter/
    end
    h=Hash.new
    h[:ip_address]=request.env['REMOTE_ADDR']
    h[:user_agent]=request.env['HTTP_USER_AGENT']
    h[:path]=request.path
    return if h[:path]=~/^\/badge/
    h[:referer]=referer
    h[:referer_domain]=URI.parse(referer).host
    h[:search_engine],h[:keywords],h[:metro_code],h[:keywords_without_metro] = extract_keywords h[:referer]
    #term_text
    h[:metro_code]=@metro_code
    t=h[:path].split("/")
    h[:term_text]= t[2].gsub("-"," ") if t and t.size==3 and @metros[t[1]] 
    h[:page_type]=@external_click_hash['page_type'] if @external_click_hash
    h[:term_text]=match.term.text.downcase if match
    referer = Referer.new(h)
    if match
      referer.match_id=match.id
    else
      referer.match_id=session[:match_id]
    end
    referer.save
    puts "+++" + referer.id.to_s
    cookies[:referer_id]=referer.id.to_s if cookies
    return referer
  end
  

end