require "../app/models/parser.rb"

class BrattlefilmParser < Parser

  def parse_page(page)
    # find date
    # find title
    # find year
    # find director
    # find description
    # find times
    return unless page.raw_body
    doc = Hpricot(page.raw_body[0..65000])
    # first find blocks representing each movie
    # movie is defined as a <p> with a first <span>  having class descriptionDate
    @date=nil
#    puts doc.inner_html
    ps = (doc/"p")
    ps.each_with_index{|p,i|
#      puts p.inner_html
      next unless (p/"span.descriptionDate")
      holder=Hash.new
      holder[:detail_link]=page.url
      next unless process_meta_block(p,holder)
      process_synopsis_block(ps[i+1],holder) if ps.size>i
#      puts holder.inspect
      header "#{holder[:title]} (#{holder[:date].to_s} #{holder[:showtime]})" 
#      puts holder[:basic_facts] unless holder[:basic_facts].blank?
#      puts holder[:synopsis]
      
      Showing.add_new_by_hash(page,holder)
    }
  end



  def process_synopsis_block(p,h)
    return unless p
    h[:synopsis]=clean(p.inner_html)
  end

  def process_meta_block(p,h)
      @date = clean( (p/"span.descriptionDate").inner_html) unless @date
      begin
        date = DateTime.parse("#{@date}, 2007")
      rescue
        puts "couldn't parse date #{@date.to_s} in brattlefilm.org,skipping"
        return
      end
      #title
      title = clean( (p/"span.descriptionTitle").inner_html)
      #showtime
      showtime = clean( (p/"span.descriptionShowtime").inner_html)
      #year 
      descriptionDetails = clean( (p/"span.descriptionDetails").inner_html)
      year = descriptionDetails.scan(/\d\d\d\d/).first
      
      #basic facts
      basic_facts = descriptionDetails
      return nil if title.empty? or date.nil? or showtime.empty?
      h[:date]=date
      h[:title]=title
      h[:showtime_string]=showtime
      h[:basic_facts]=basic_facts
      h[:year]=year
      year = descriptionDetails.scan(/\d\d\d\d/).first
      
      #description
  end

  
end
