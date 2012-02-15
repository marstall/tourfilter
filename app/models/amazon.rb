require 'rubygems'
require 'hpricot'
require "net/http"
require 'open-uri'

ECS_ACCESS_KEY_ID = '1CXR6M1N827JKZRCNE82'

class Amazon
  
  def self.fetch_hpricot(url)
    xml=fetch_url(url)
    Hpricot.XML(xml)
  end

  def self.fetch_url(url_text)
    begin
      url_text=URI.encode(url_text)
      user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      obj = open(url_text, "User-Agent" => user_agent)
      obj.read
    rescue => e
      handle_exception(e)
      puts "exception loading url '#{url_text}': #{$!}"
    end
  end

  def self.fetch(action,params)
    url =  "http://ecs.amazonaws.com/onca/xml?Service=AWSECommerceService&AWSAccessKeyId=#{ECS_ACCESS_KEY_ID}"
    url += "&Operation=#{action}&"
    params.each_key{|key|
      value = params[key]
      url+="&#{key}=#{value}"
    }
#    puts url
    fetch_hpricot(url)
  end

#ASIN
#DetailPageURL
#SalesRank
#SmallImageURL
#MediumImageURL
#LargeImageURL
#SmallImageURL
#Artist
#Binding
#Format
#Label
#ListPrice
#NumberOfDiscs
#ProductGroup
#Publisher
#ReleaseDate
#Studio
#Title
#UPC
#LowestNewPrice
#LowestUsedPrice
#TotalNew
#TotalUsed
#BrowseNodes




  def self.do_stuff(fast_forward=false,refresh=false)
    puts "doing amazon stuff"
    # go through all artists
    # fetch albums + other meta-data by them
    # store albums + meta data in items table
    Term.find(:all).each{|term|
      next unless term and term.text and term.text.strip.size>2 
      if fast_forward
        if Item.find_by_term_text(term.text)
          "puts fast-forwarding past #{term.text} ..."
          next
        end
      end
      puts "fetching item data from amazon for #{term.text} ..."
      doc = fetch( :ItemSearch,
                    {
                      :ResponseGroup => 'Large',
                      :SearchIndex => 'Music',
                      :Artist => term.text
                    }
      )
      (doc/:Item).each{|_item|
#          begin
            puts _item.inspect
            return
            asin = (_item/:ASIN).first.inner_html
            item = Item.find_by_asin_and_term_text(asin,term.text)
            next if item and not refresh
            new_item=item
            item||=Item.new
            item.term_id=term.id
            puts "old: #{item.detail_page_url}"
            item.term_text=term.text
            item.source_reference="amaz"
            item.asin=asin
            item.detail_page_url=(_item/:DetailPageURL).inner_html
            item.sales_rank=(_item/:SalesRank).inner_html
            item.small_image_url=((_item/:SmallImage)/:URL).inner_html
            item.medium_image_url=((_item/:MediumImage)/:URL).inner_html
            item.large_image_url=((_item/:LargeImage)/:URL).inner_html
            item.artist=(_item/:Artist).inner_html
            item.binding=(_item/:Binding).inner_html
            item.format=(_item/:Format).inner_html
            item.label=(_item/:Label).inner_html
            item.list_price=(_item/:ListPrice).inner_html
            item.number_of_discs=(_item/:NumberOfDiscs).inner_html
            item.product_group=(_item/:ProductGroup).inner_html
            item.publisher=(_item/:Publisher).inner_html
            release_date = (_item/:ReleaseDate).inner_html
            item.release_date=Date.parse(release_date) rescue nil
            item.studio=(_item/:Studio).inner_html
            item.title=(_item/:Title).first.inner_html
            item.upc=(_item/:UPC).inner_html
            item.lowest_new_price=((_item/:LowestNewPrice)/:Amount).inner_html
            item.lowest_used_price=((_item/:LowestUsedPrice)/:Amount).inner_html
            item.total_new=(_item/:TotalNew).inner_html
            item.total_used=(_item/:TotalUsed).inner_html
            item.save
            puts "new: #{item.detail_page_url}"
            if new_item
              puts "saved new '#{item.title}' ..." 
            else
              puts "saved updated '#{item.title}' ..." 
            end

#          rescue => e
#            puts e
#          end
        }
    }
  end
end
