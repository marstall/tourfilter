require "net/http"
require 'open-uri'

class AdminController < ApplicationController  
 # include Parser
  
  before_filter :must_be_admin
    
  def admin
    render :action => "admin"
  end
  
  def admin_matches
    @problem_pages=Page.find_all_problem_pages
  end
  
  def validate_import
    @at=ArtistTerm.find(params[:id])
    @at.status='valid'
    @at.save
  end

=begin
CREATE TABLE `images` (
  `id` int(11) NOT NULL auto_increment,
  `url` varchar(255) default NULL,
  `width` int(4) default NULL,
  `height` int(4) default NULL,
  `alt_text` varchar(1024) default NULL,
  `term_id` int(11) default NULL,
  `created_at` datetime default NULL,
  `term_text` varchar(128) default NULL,
  PRIMARY KEY  (`id`),
  UNIQUE KEY `url` (`url`)
)
=end

  def preview_images
    sql = <<-SQL
      select i.*
      from terms
      left join tourfilter_shared.images i
        on (i.term_text = terms.text)
      left join matches
        on (terms.id=matches.term_id)

      and i.term_text is not null
      and i.created_at>adddate(now(),interval -7 day)
      group by i.term_text
      order by i.created_at desc
    SQL
    @images = Image.find_by_sql(sql)
  end

  def find_problem_terms
    num_days=params[:id]||180
    sql = <<-SQL
      select terms.*,matches.date_for_sorting date
      from terms
      left join tourfilter_shared.images i
        on (i.term_text = terms.text)
      left join matches
        on (terms.id=matches.term_id)
      where (matches.status='notified' or matches.status='approved') and matches.day is not null and matches.time_status='future'
      and matches.date_for_sorting<adddate(now(),interval #{num_days} day) and matches.date_for_sorting>adddate(now(),interval -1 day)
      and i.problem='yes'
      group by terms.text
      order by matches.date_for_sorting asc
    SQL
    Term.find_by_sql(sql)
  end

  def add_images
    term_text=params[:term_text]
    @one_only=false
    if term_text
      @one_only=true
      @terms=[Term.find_by_text(term_text)]
      return
    end
    num_days=params[:id]||180
    sql = <<-SQL
      select terms.*,matches.date_for_sorting date
      from terms
      left join tourfilter_shared.images i
        on (i.term_text = terms.text)
      left join matches
        on (terms.id=matches.term_id)
      where (matches.status='notified' or matches.status='approved') and matches.day is not null and matches.time_status='future'
      and matches.date_for_sorting<adddate(now(),interval #{num_days} day) and matches.date_for_sorting>adddate(now(),interval -1 day)
      and i.term_text is null
      group by terms.text
      order by matches.date_for_sorting asc
    SQL
    @problem_terms = find_problem_terms
    @terms = Term.find_by_sql(sql)
  end


  def fetch_url(url_text)
    begin
      user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      obj = open(url_text, "User-Agent" => user_agent)
      obj.read
    rescue Exception
      puts "error fetching url: #{$!}"
      puts "continuing ... "
    end
  end

  def handle_myspace_image(url)
    doc = fetch_hpricot(url)
    jpg_url = (doc/"img#userImage").first.attributes['src']
    return jpg_url,url
  end
  
  def handle_wikipedia_image(url,text)
    doc = fetch_hpricot(url)
    logger.info("+++"+url)
    jpg_url = (doc/"a.image").first.attributes['href']
    jpg_url = "http://en.wikipedia.org#{jpg_url}" if jpg_url !~ /http/
    doc = fetch_hpricot(jpg_url)
    jpg_url = (doc/"img").first.attributes['src']
    return jpg_url,"http://en.wikipedia.org/wiki/#{Term.make_wikipedia_url_text(text)}"
  end

# http://www.tourfilter.local:3000/admin/set_image/http:%2F%2Fviewmorepics.myspace.com%2Findex.cfm%3Ffuseaction=viewImage%26friendID=
# 322115599%26albumID=1076486%26imageID=10084244/http:%2F%2Fviewmorepics.myspace.com%2Findex.cfm%3Ffuseaction=user.viewPicture%26friendID=322115599%26albumId=1076486

# corresponding bookmarklet: 
# javascript:function encode(url){url = url.replace(/\//g,%22%252F%22);url = url.replace(/\?/g,%22%253F%22);url = url.replace(/\&/g,%22%2526%22);return url;};referer=encode(document.referrer);url=encode(location.href);location.href=%22http://www.tourfilter.local:3000/admin/set_image/%22+url+%22/%22+referer

  def extract_domain(url)
      return URI.parse(url).host rescue url
  end

  def unfeature
    term_text=params[:term_text]
    do_cache_stuff(term_text)
    term = Term.new
    term.text=term_text
    term.delete_image
    flash[:notice]="deleted #{term.text}'s image!"
    redirect_to(request.env['HTTP_REFERER'])
  end

  def do_cache_stuff(term_text)
    expire_term_fragment(term_text)
  end

  def set_image
    @term_text = term_text = get_cookie("term_text")
    logger.info "+++ cookie term_text #{@term_text}"
    do_cache_stuff(@term_text.strip.to_s)
    referer = referer = params[:referer]
    url = params[:url]
    return if url=~/\.rdf/
    return if referer=~/\.rdf/
    # do special stuff to extract real referer from google images frame url
    if url=~/myspace/ and url !~ /.jpg$/
      url,referer = handle_myspace_image(url)
    end
    if url=~/wikipedia/ and url !~/jpg$/
      url,referer = handle_wikipedia_image(url,term_text)
    end
    @url = url
    if referer=~/images.google.com/
      offset = referer.index("imgrefurl=")+10
      if offset
        s = s = referer[offset..-1]
        o2 = offset2=s.index("&")
        referer = s[0..offset2-1]
      end
    end
    referer="http://#{extract_domain(url)}" unless referer and not referer.empty?
    image = Image.find_by_term_text(term_text)
    if not image
      image = Image.new
      image.term_text = term_text
    end
    image.url = url
    image.source_url = referer
    image.problem='no'
    image.save
    image.process
    @image=image
    @referer = referer
  end

  def invalidate_import
    @at=ArtistTerm.find(params[:id])
    @at.status='invalid'
    @at.save
  end

  def toggle_match_status
    @match = Match.find(params[:id])
    if @match.status=='new'
      @match.status='approved'
    else
      @match.status='new'
    end
    @match.save
  end
  
  def correct_date
    id = params[:id]
    match = Match.find(id)
    match.day=params[:day]
    match.month=params[:month]
    # now determine the year. if the month of the event is 1,2 or 3 and the current month is 10, 11 or 12 then increment the year by one.
    year=DateTime.now.year
    year=DateTime.now.year+1 if DateTime.now.month>=10 and match.month<=3
    # if the month of the event is 10,11 or 12 and the current month is 1, 2 or 3 then decrement the year by one.
    year=DateTime.now.year-1 if DateTime.now.month<=3 and match.month>=10
    match.year=year
    match.date_for_sorting=DateTime.new(match.year,match.month,match.day)
    match.save
    render(:inline=>"#{match.month}/#{match.day} set.")
  end
  
  def manage_match
    match_id=params[:id]
    if match_id
      @match = Match.find(match_id)
      if params[:status]
        @match.status=params[:status]
        @match.save
      end
    end
  end
  
  def index
    admin
  end
  
end
