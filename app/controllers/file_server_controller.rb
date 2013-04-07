class FileServerController < ApplicationController
  include FileUtils

    def fetch_url(url)
      agent = WWW::Mechanize.new 
      dir="#{RAILS_ROOT}/public/remote_file_cache/"
      mkdir dir rescue
      digest = Digest::MD5.hexdigest(url)
      
      filename="#{dir}#{digest}"
      return File.read(filename),true if File.exists?(filename)
  #    atime = File.atime(filename)
  #    puts "file exists?: #{File.exists?(filename)}"
  #    puts "atime: #{atime}"
  #    puts "now: #{Time.now}"
  #    puts "cache_timeout: 180"
      page = agent.get(url)
  #    puts "creating filename for url #{url}: #{filename}"
      rm_rf(filename)
      file = File.new(filename,"w")
      file.write(page.body)
      file.close
      return "/remote_file_cache/#{digest}"
    end

  
  def request(url)
    if ENV['RAILS_ENV']=='development'
      return fetch_url(url)
    else
      return url
    end
  end
  
  def s3_request(filename)
    request("http://s3.amazonaws.com/tourfilter.com/#{filename}")
  end
  
  def image_request
    s3_request(Image.filename(params[:id],params[:shape],:params[:size]))
  end

end
