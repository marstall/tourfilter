module UrlFetcher
 
  include FileUtils
  
  # look in cache - if it finds it there, return it. else wait <delay> seconds and fetch it
  def fetch_url(url,delay=0) # returns body + was_cached
    agent = WWW::Mechanize.new 
    cache_timeout=144*60*60 # 1/2 day
    digest = Digest::MD5.hexdigest(url)
    dir="/tmp/tourfilter/"
    mkdir dir rescue
    filename="#{dir}#{digest}"
#    puts filename
    # return the cached version if it exists and it is less that <cache_timeout> seconds old
    return File.read(filename),true if File.exists?(filename) and Time.now-File.atime(filename)<cache_timeout
#    atime = File.atime(filename)
#    puts "file exists?: #{File.exists?(filename)}"
#    puts "atime: #{atime}"
#    puts "now: #{Time.now}"
#    puts "cache_timeout: 180"
#    puts "Time.now-atime: #{Time.now-atime}"
    sleep delay
    page = agent.get(url)
#    puts "creating filename for url #{url}: #{filename}"
    rm_rf(filename)
    file = File.new(filename,"w")
    file.write(page.body)
    file.close
    return page.body,false
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
      uri_str = get_final_url(uri_str)
      puts "downloading #{uri_str} ... "
      uri = URI.parse(uri_str)
      filename=String.new
      base_filename=String.new
      completed=false
      timeout(timeout_value) do
          Net::HTTP.start(uri.host,80) {|http|
          @before=Time.new
          base_filename=uri_str.gsub(/[?:\/&%]/,"_")
          base_filename=base_filename.gsub(/%../,"_")
          filename=@file_root + base_filename
          if File.exists?(filename)
            puts "file already exists, skipping."
            return filename 
          end
          puts "+++ getting #{uri.host} #{uri.path}"
          http.request_get(uri.path) {|response|
            content_type = response['content-type']
            raise "wrong type: #{content_type}" if content_type !~ /image/
            num_bytes=0  
            body=String.new
            File.delete("tmp.jpg") if File.exists?("tmp.jpg")
            tmp_file = open("tmp.jpg","w")
            puts " +++ here"
            response.read_body do |str|   # read body now
              puts str.size
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