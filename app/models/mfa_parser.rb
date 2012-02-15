require "../app/models/parser.rb"

class MfaParser < Parser

  def parse_page(page)
    # get the film precis listings, extract metadata:title,date, ticket buying link
    # fetch detail page for each, extract synopsis, photo, showtime
    return unless page.raw_body
    h = Hash.new
    doc = Hpricot(page.raw_body[0..65000])
    (doc/"td.center_content_feature").each{|elem|
#      puts elem.inner_html
      process_meta_block(elem,h)
#      puts
#      puts "------------------------------------------"
#      puts h[:title]
#      puts h[:year]
#      puts h[:date_string]
#      puts h[:image_url]
#      puts h[:synopsis]
      Showing.add_new_by_hash(page,h) rescue next
    }
  end

  def process_meta_block(elem,h)
    shb = (elem/"a.sub_head_blue")
    return unless shb and not shb.empty?
    h[:title] = shb.inner_html
    detail_link = shb.first.attributes['href'] 
    h[:detail_link] = "http://www.mfa.org#{detail_link}" 
    process_detail_page(h[:detail_link],h)
  end  

  def process_detail_page(url,h)
    debug=true 
    synopsis=nil
#    puts "DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG" if debug
#    puts url
    doc = fetch_hpricot(url)
#    puts doc.inner_html if debug
#    puts "END DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG DEBUG" if debug
    elem = (doc/"td.center_content_feature").first rescue return
    shbs = (elem/"span.sub_head_black")

    # time
    h[:showtime_string] = clean(shbs[1].inner_html) rescue return
    
    # date
    h[:date_string] = clean(shbs[2].inner_html) rescue return
    
    # synopsis
    synopsis = elem.inner_html
    start=synopsis.index("<i>")
    if start
      synopsis=synopsis[start+3..synopsis.size-1]
      start=synopsis.index("<i>")
      if start
        synopsis=synopsis[start..synopsis.size-1]
        _end = synopsis.index("<br")
        synopsis=synopsis[0.._end-1] if _end
      end
    end
    h[:synopsis]=synopsis

    # year
     years = synopsis.scan(/\d\d\d\d/)
     h[:year] = years.first if years
    
    # image
    h[:image_url]=nil
    (doc/"img").each{|img|
      src = img.attributes['src']
      next unless src=~/jpg/
      h[:image_url] = "http://www.mfa.org#{src}"
      #break
    }
  end


  
end
