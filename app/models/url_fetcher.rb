require 'mechanize'
module UrlFetcher
 
  include FileUtils
  
  # look in cache - if it finds it there, return it. else wait <delay> seconds and fetch it
  def fetch_url(url,delay=0) # returns body + was_cached
    agent = WWW::Mechanize.new 
    agent.user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
  
    cache_timeout=144*60*60 # 1/2 day
    digest = Digest::MD5.hexdigest(url)
    dir="/tmp/tourfilter/"
    mkdir dir rescue
    filename = "#{dir}#{digest}"
    s = "#{dir}#{digest}"
    return File.read(s) if File.exists?(s) and Time.now-File.atime(s)<cache_timeout
    sleep delay
    page=nil
    begin
      puts "+++ FETCHING! #{url} ..."
      page = agent.get(url)
    rescue TimeoutError
      puts "FAILED! fetching #{url}, trying via proxy ..."
      agent = WWW::Mechanize.new 
      agent.user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      agent.set_proxy("208.113.128.45",51234) # try it with the proxy if it failed
      page = agent.get(url)      
    end
    rm_rf(s)
    file = File.new(s,"w")
    file.write(page.body)
    file.close
    return page.body
  end
  

  def fetch_url_no_cache(url_text,fake_user_agent=true)
    begin
      if fake_user_agent
        user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
      else
        user_agent = "tourfilter.com crawler - email info@tourfilter.com"
      end
      obj = open(url_text, "User-Agent" => user_agent)
      return obj.read
    rescue TimeoutError
      puts "+++ timed out: #{url_text}"
    rescue => e
      puts "exception loading url '#{url_text}': #{$!}"
    end

  end
   
 def get_final_url(uri_str,limit=5)
#   puts "getting final url for #{uri_str} ... "
      if limit==0
        puts "HTTP redirect too deep"
      end
      uri = URI.parse(uri_str)
#      raise ArgumentError, 'HTTP redirect too deep' if limit == 0
      response=Object.new
      begin
        timeout(7) do
            Net::HTTP.start(uri.host) {|http|
              response = http.request_head(uri.path)
              case response
                when Net::HTTPSuccess     then 
#                  puts "\t\t\t\t\t\t\t\t\t\t!!!success"
                  response
                when Net::HTTPRedirection then 
                  puts "redirecting to #{response['location']}"
                  uri_str = get_final_url(response['location'].gsub(/\s/,"%20"), limit - 1)
                else
                  response.error!
                end
            }
#          puts "response headers:"
          response.each_key{|key|
#            puts "#{key}: #{response[key]}"
          }
        end
    rescue TimeoutError
      puts "\t\t\t\t\t\t\t\t\t\t???timed out"
    rescue => e
      puts "\t\t\t\t\t\t\t\t\t\t???#{e}"
    end
#    puts "returning #{uri_str} from get_final_url"
    uri_str
 end
 
  def download_jpg(uri_str,timeout_value=60)
      @file_root||="/tmp/"
      uri_str.gsub!(" ","%20")
#      uri_str = get_final_url(uri_str)
#      puts "downloading #{uri_str} ... "
      uri = URI.parse(uri_str)
      filename=String.new
      base_filename=String.new
      completed=false
      timeout(timeout_value) do
          Net::HTTP.start(uri.host,uri.port) {|http|
          @before=Time.new
          base_filename=uri_str.gsub(/[?:\/&%]/,"_")
          base_filename=base_filename.gsub(/%../,"_")
          filename=@file_root + base_filename
          if File.exists?(filename)
            puts "file already exists, skipping."
            return filename 
          end
          http.request_get(uri.path) {|response|
            content_type = response['content-type']
            raise "wrong type: #{content_type}" if content_type !~ /image/
            num_bytes=0  
            body=String.new
            File.delete("tmp.jpg") if File.exists?("tmp.jpg")
            tmp_file = open("tmp.jpg","w")
            response.read_body do |str|   # read body now
              num_bytes+=str.size
              tmp_file.print(str)
            end
            tmp_file.close
#            return nil if num_bytes>500000
            mv("tmp.jpg",filename) 
            puts "downloaded #{Integer(num_bytes/(1024))}K to #{filename}"
          }
        }
        completed=true
      end
      if completed
        return filename
      else
        return nil
      end
  end
end  