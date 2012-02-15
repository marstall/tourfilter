class Echonest
  
  require 'rss/1.0'
  require 'rss/2.0'
  require 'rss/dublincore'
  require 'rss/syndication'
  require 'rss/content'
  require 'rss/trackback'

  include UrlFetcher
  
  def initialize(logger=nil)
    @logger = logger if logger
  end
  
  def self.logos
    {
      'pitchfork.com'=>'/images/pitchfork.png',
      'avclub.com'=>'/images/avclub.jpg',
      'tinymixtapes.com'=>'/images/tinymixtapes.png',
      'aquariusrecords.org'=>'/images/aquariusrecords.gif',
      'rollingstone.com'=>'/images/rollingstone.gif',
      'ew.com'=>'/images/ew.gif',
      'prefixmag.com'=>'/images/prefixmag.gif',
      'pastemagazine.com'=>'/images/pastemagazine.gif',
      'forcedexposure.com'=>'/images/forcedexposure.gif',
      'allaboutjazz.com'=>'/images/allaboutjazz.png',
      'undertheradarmag.com'=>'/images/undertheradarmag.jpg',
      'spin.com'=>'/images/spin.gif',
      'villagevoice.com'=>'/images/villagevoice.png',
      'npr.org'=>'/images/npr.gif',
      'bbc.co.uk'=>'/images/bbc.png',
      'nme.com'=>'/images/nme.jpg'
    }
  end
  
  def self.desired
    ["pitchfork.com","avclub.com","aquariusrecords.org","tinymixtapes.com"]
  end
  
  def self.desired_hash
    h=Hash.new
    desired.each_with_index{|desired,i|h[desired]=i}
    return h
  end
  
  def self.names
    {
      "aquariusrecords.org"=>"Aquarius Records",
      "tinymixtapes.com"=>"Tiny Mix Tapes",
      "pitchfork.com"=>"Pitchfork",
      "avclub.com"=>"The Onion AV Club"
    }
  end
  
  def self.logo_adj
    {
      'avclub.com'=>2,
      'pitchfork.com'=>3
    }
  end
  

  def fetch_rss(type,term_text)
    url ="http://developer.echonest.com/artist/#{Term.encode(term_text)}/#{type}.rss"
    begin
      rss_source = fetch_url_no_cache(url,false)
      rss = RSS::Parser.parse(rss_source,false)
      return rss.items
    rescue
      return []
    end
  end
  
  @@source_counts=Hash.new
=begin
 CREATE TABLE `articles` (
  `id` int(11) NOT NULL auto_increment,
  `term_text` int(11) default NULL,
  `url` varchar(255) default NULL,
  `title` varchar(255) default NULL,
  `description` text default NULL,
  `domain` char(64),
  PRIMARY KEY  (`id`)
)
=end
  def download_and_save_articles_for(term_text)
    _articles = get_articles(term_text,'reviews')
    articles=Array.new
    _articles.each{|_article|
      article = Article.new
      article.term_text=term_text
      article.url=_article[:url]
      article.title=_article[:description]
      article.domain=_article[:host]
      article.priority=Echonest.desired_hash[article.domain]
      article.save unless article.already_exists?
      articles<<article
    }
    return articles
  end

  def get_articles(term_text,article_type)
    items=fetch_rss(article_type,term_text)
    articles=Array.new
    mentioned=Hash.new
    items.each{|item|
      begin
        url = item.link
        title = item.title
        description=item.description
        uri = URI.parse(url)
        domain=uri.host
        domain.sub!("www.","")
        next if mentioned[domain]
        mentioned[domain]=true
        @@source_counts[domain]||=0
        @@source_counts[domain]+=1
        articles<<{:host=>domain,:url=>url,:title=>title,:description=>description}
      rescue
      end
    }
    return articles  
  end
  
  def self.source_counts
    puts @@source_counts.inspect
    ra=Array.new
    @@source_counts.each_key{|key|
      ra<<{:domain=>key,:count=>@@source_counts[key]}
      }
    ra.sort!{|x,y|y[:count]<=>x[:count]}
    return ra
  end
  
end

=begin
NEWS
27	pitchfork.com
22	prefixmag.com
21	filtermagazine.com
21	spin.com
21	tinymixtapes.com
19	pastemagazine.com
16	nme.com
15	punknews.org
13	sputnikmusic.com
13	undertheradarmag.com
13	allaboutjazz.com
12	jambands.com
11	mtv.com
11	music-mix.ew.com
11	ultimate-guitar.com
9	magnetmagazine.com
9	adequacy.net
8	mog.com
8	vh1.com
7	filter-mag.com
7	altpress.com
7	popmatters.com
7	music.yahoo.com
6	rollingstone.com
6	americansongwriter.com
6	hickorywind.org

BLOGS
16	bostonbandcrush.com
13	hangout.altsounds.com
13	consequenceofsound.net
10	sharemyplaylists.com
9	spinner.com
9	glidemagazine.com
8	mickieszoo.blogspot.com
8	brooklynvegan.com
8	thelineofbestfit.com
8	prefixmag.com
7	backseatsandbar.com
7	popwreckoning.com
7	community.livejournal.com
6	indiependentmusic.blogspot.com
6	poplibrarian.com
6	spin.com
6	huffingtonpost.com
5	losanjealous.com
5	countmeoutblog.blogspot.com
5	idolator.com
5	yuforum.net
5	indieforbunnies.com

REVIEWERS
rollingstone.com 41
ew.com 33
pitchfork.com 30
ultimate-guitar.com 26
robertchristgau.com 24
bbc.co.uk 24
cokemachineglow.com 23
prefixmag.com 23
aquariusrecords.org 21
adequacy.net 18
tinymixtapes.com 18
slantmagazine.com 17
lostatsea.net 17
sputnikmusic.com 16
nme.com 15
uncut.co.uk 14
pastemagazine.com 14
noripcord.com 13
stylusmagazine.com 13
ink19.com 12
pitchforkmedia.com 11
austinchronicle.com 11
avclub.com 11
dustedmagazine.com 11
thephoenix.com 10
drownedinsound.com 10
forcedexposure.com 10
filter-mag.com 10
neumu.net 9
nowtoronto.com 9
uk.launch.yahoo.com 8
altpress.com 7
blender.com 7
allaboutjazz.com 6
globalrhythm.com 5
billboard.com 5
almostcool.org 5
undertheradarmag.com 5
urb.com 5
jazztimes.com 4
boston.com 4
mojo4music.com 4
latimesblogs.latimes.com 4
spin.com 4
popmatters.com 4
mimaroglumusicsales.com 4
jazzreview.com 4
sfgate.com 3
villagevoice.com 3
rapreviews.com 2
jazz.com 2
musicomh.com 2
magnetmagazine.com 1
splendidezine.com 1
nudeasthenews.com 1
=end

=begin
<?xml version="1.0" encoding="utf-8"?>
<rss version="2.0">
<channel>
<title>Reviews results for Yeasayer</title>
<link>http://developer.echonest.com/</link>
<description>This feed lists web results for Yeasayer</description>
<language>en-us</language>
<lastBuildDate>Thu, 18 Feb 2010 21:55:00 +0000</lastBuildDate>
<item>
  <title>YEASAYER - Odd Blood (from Aquarius Records)</title>
  <link>http://aquariusrecords.org/cat/newest.html#YEASAYER__Odd%20Blood</link>
  <description>These guys are really tough to figure out, we were never that into them actually, until we heard one of their tracks on a Mojo compilation of all places, and even weirder it was a sort of No Depression / Americana style collection, with groups like Iron &amp; Wine, The Low Anthem, and their sound, while slightly twangy, was way more quirky and electronic, a sort of twisted cabaret pop, we ended up digging that record quite a bit, so were excited to hear this new one.  Right off the bat, it's a weird......</description>
<dc:creator xmlns:dc="http://purl.org/dc/elements/1.1/">Gathered by The Echo Nest</dc:creator>
<pubDate>Thu, 18 Feb 2010 21:55:00 +0000</pubDate><guid>http://aquariusrecords.org/cat/newest.html#YEASAYER__Odd%20Blood</guid></item>
</channel>
</rss>
=end