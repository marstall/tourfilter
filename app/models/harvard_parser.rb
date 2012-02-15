require "../app/models/parser.rb"

class HarvardParser < Parser

#
#      <td><p class="caldate">7</p>
#        <p class="caltime">7 pm</p>
#        <p class="calfilm"><a href="/hfa/films/2007fall/sembene.html#moolade">Mooladé;</a><br />
#          <a href="/hfa/films/2007fall/sembene.html#moolade">Making of  Mooladé</a><a href="/hfa/films/2007fall/sembene.html#moolade"></a></p>
#        <p class="calnote">Director in Person </p>
#        <p class="caltime">9:30 pm </p>
#        <p class="calfilm"><a href="/hfa/films/2007fall/sembene.html#black">Black Girl </a></p>
#       </td>
#
        
  def parse_page(page)
    # find date
    # find title
    # find year
    # find times
    return unless page.raw_body
    doc = Hpricot(page.raw_body[0..65000])
    # first find blocks representing each movie
    # movie is defined as a <p> with a first <span>  having class descriptionDate
    @date=nil
    tds = (doc/"td")
    process_meta_block(page,tds)
  end
  
  def process_meta_block(page,tds)
    tds.each_with_index{|td,i|
      next if td.inner_html =~/no screenings/i
      day = (td/"p.caldate").inner_html rescue nil
      next if day.nil? or day.strip.empty?
      p_caltime = (td/"p.caltime")
      next unless p_caltime
      p_caltime.each_with_index{|p,i|
        begin
          holder=Hash.new
          holder[:date]=Date.new(Integer(Time.now.year),Integer(page.month),Integer(day))
          holder[:showtime_string]=p.inner_html
          Showing.output(holder)
          title_p = (td/"p.calfilm")[i]
          holder[:title]=clean(title_p.inner_html) rescue next
          detail_link=(title_p/"a").first.attributes['href']  rescue nil
          anchor=detail_link[detail_link.index("#")..detail_link.size] rescue detail_link
          holder[:detail_link]="http://hcl.harvard.edu#{detail_link}"
          process_detail_page(holder[:detail_link],anchor,holder)
          Showing.add_new_by_hash(page,holder)
#        rescue
#          puts "+++error"
        end
      }
    }
  end
  
#<p class="datestrip">Friday September 14 at 7 pm<a name="basque" id="basque"></a></p>
#<h3>  <img src="/hfa/images/films/2007fall/spain_La-Pelota-Vasca.jpg" width="250" height="180" class="film_image" />
#       The Basque Ball (<em>La Pelota Vasca</em>) </h3>
#<p class="filminfo">  Directed by Julio Medem<br />
#Spain 2003, video, color, 110 min. <br />
#Spanish, Basque, English and French with English subtitles</p>
#<p>In the wake of the 2004 Madrid  train bombings, the cause of the Basque people [etc] ...</p>


  def process_detail_page(url,anchor,h)
    puts url
    return unless anchor
    doc = fetch_hpricot(url)
    # find director
    # find synopsis_block
    # find basic_facts
    # find language
    # find image
    anchor.gsub!("#","")
    (doc/"a").each{|a|
      next unless a.attributes['name']==anchor

      img_block = a.parent.nodes_at(2)
      basic_facts_block = a.parent.nodes_at(4)
      synopsis_block = a.parent.nodes_at(6)
      
      image_url = (img_block/"img").first.attributes['src'] rescue nil
      h[:image_url] = "http://www.hcl.harvard.edu#{image_url}" if image_url
      h[:basic_facts] = clean(basic_facts_block.inner_html)
      h[:synopsis] = synopsis_block.inner_html
    }
    
  end

  

end
