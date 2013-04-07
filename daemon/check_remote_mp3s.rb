$mode='daemon'
# check_remote_mp3s daemon for tourfilter which:
# loops through all MP3s
# for each:
#   fetch the mp3, following redirects
#   verify that the file is an MP3
#   verify that the file loads within n seconds
#   mark the track row with the status outcome and the ttr
# update all terms' mp3 track counts

require "rubygems"
require "../config/environment.rb"

require "net/http"
require "logger"
#require 'open-uri'
require "../app/models/playlist.rb"
require "../app/models/term.rb"
require "../app/models/track.rb"
require "timeout" 
#require "../app/models/s3.rb"

def initialize_daemon(metro_code)
  # setup mail-server configuration params
  rails_env = ENV['RAILS_ENV']
  puts "initializing daemon in #{rails_env} mode ..."
  if (rails_env!='production')
    @tourfilter_base="http://localhost:3000"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"localhost",
      :database=> "tourfilter_#{metro_code}")
    ActionMailer::Base.smtp_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
    }
  else
    @tourfilter_base="http://www.tourfilter.com"
    ActiveRecord::Base.establish_connection(
      :adapter=>"mysql",
      :host=>"127.0.0.1",
      :username=>'chris',
      :password=>'chris',
      :database=> "tourfilter_#{metro_code}")
    ActionMailer::Base.smtp_settings = {
      :address => "secure.seremeth.com",
      :authentication => :plain,
      :user_name => "chris@psychoastronomy.org",
      :password => "montgomery"
    }
  end
end

 def check_mp3_header(uri_str, limit = 5)
#   puts "#{uri_str} ... "
      # You should choose better exception.
#      puts "fetching #{uri_str}"
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
                  puts "\t\t\t\t\t\t\t\t\t\t!!!success"
                  response
                when Net::HTTPRedirection then 
         #         puts "redirecting to #{response['location']}"
                  check_mp3_header(response['location'], limit - 1)
                else
                  response.error!
                end
            }
          puts "response headers:"
          response.each_key{|key|
            puts "#{key}: #{response[key]}"
          }
        end
    rescue TimeoutError
      puts "\t\t\t\t\t\t\t\t\t\t???timed out"
    rescue => e
      puts "\t\t\t\t\t\t\t\t\t\t???#{e}"
    end
end

def check_mp3(uri_str,timeout_value=7,num_bytes_required=2000)
    uri_str = get_final_url(uri_str)
    puts "checking #{uri_str} ... "
    uri = URI.parse(uri_str)
    timeout(timeout_value) do
        Net::HTTP.start(uri.host,uri.port) {|http|
        @before=Time.new
        http.request_get(uri.path) {|response|
          content_type = response['content-type']
          raise "Wrong Type: #{content_type}" if content_type !~ /audio/
          num_bytes=0
          response.read_body do |str|   # read body now
            num_bytes+=str.size
            if num_bytes>num_bytes_required
              ttl = Time.new-@before
              return ttl
            end

          end
        }
      }
    end
end


def fetch_url(url_text)
#    user_agent = "Mozilla/5.0 (Macintosh; U; PPC Mac OS X; en-us) AppleWebKit/XX (KHTML, like Gecko) Safari/YY"
    user_agent = "tourfilter.com crawler - email info@tourfilter.com"
    obj = open(url_text, "User-Agent" => user_agent)
    obj.read
end

def header (s)
  line ="****************************************************************"
  puts line
  puts line
  puts "***************** "+s
  puts line
  puts line  
end

def update_term_track_counts
  Term.find_all_with_hype_tracks.each{|term|
    term.num_mp3_tracks=Track.count_by_term_id(term.id,'mp3')
    term.save
    puts "#{term.text} has #{term.num_tracks} mp3 tracks."
    }
end

def check_mp3s
#  check_mp3("http://www.psychoastronomy.org/blog")
#  check_mp3("http://tourfilter.com/calendar")
#  check_mp3("http://hype.non-standard.net/serve/r/400/9673/Thalia_Zedek-Everything_Unkind.mp3")
#  return
  tracks = Track.find_by_file_type("mp3")
  tracks.each_with_index{|track,i|
#    return if i>num_to_retrieve
    url = track.url
    begin
      ttl = check_mp3(url,4) # 4 second timeout
      track.ttl=ttl
      track.status="valid"
      puts "\t\t\t\t\t\t\t\t\t\t\t\t\tSUCCESS! (#{ttl}ms)"
    rescue TimeoutError
      track.ttl=100
      track.status="invalid"
      puts "\t\t\t\t\t\t\t\t\t\t\t\t\tfailure: Timeout"
    rescue => e
      track.status="invalid"
      puts "\t\t\t\t\t\t\t\t\t\t\t\t\tfailure: #{e}"
    end
    track.save
  }
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
#                  puts "redirecting to #{response['location']}"
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

# will either return the number of ms it took to load num_bytes_required bytes, or throw an exception.
# follows any redirections (up to 5)
def download_mp3(uri_str,timeout_value=60)
    uri_str = get_final_url(uri_str)
    uri_str = uri_str.gsub(".nyud.net:8080","")
    puts "downloading #{uri_str} ... "
    uri = URI.parse(uri_str)
    filename=String.new
    base_filename="/home/chris/tourfilter/public/mp3s/"
    FileUtils.mkdir(base_filename) rescue
    completed=false
    timeout(timeout_value) do
        Net::HTTP.start(uri.host,uri.port) {|http|
        @before=Time.new
        base_filename="#{base_filename}#{uri_str.gsub(/[?:\/&%]/,'_')}"
        base_filename=base_filename.gsub(/%../,"_")
        filename=base_filename
        if File.exists?(filename)
          puts "file already exists, skipping."
          return base_filename 
        end
        http.request_get(uri.path) {|response|
          content_type = response['content-type']
          raise "Wrong Type: #{content_type}" if content_type !~ /audio/
          num_bytes=0  
          body=String.new
          File.delete("tmp.mp3") if File.exists?("tmp.mp3")
          tmp_file = open("tmp.mp3","w")
          response.read_body do |str|   # read body now
            num_bytes+=str.size
            tmp_file.print(str)
          end
          tmp_file.close
          return nil if num_bytes<500000
          FileUtils.mv("tmp.mp3",filename)
#          puts "moving #{filename} to s3 ..."
#          S3.move_to_s3(filename)
#          puts "moved, file should be at http://s3.amazonaws.com/tourfilter.com/#{filename}"
          puts "downloaded #{Integer(num_bytes/(1024))}K"
        }
      }
      completed=true
    end
    if completed
      return base_filename
    else
      return nil
    end
end

def download_mp3s
#  check_mp3("http://www.psychoastronomy.org/blog")
#  check_mp3("http://tourfilter.com/calendar")
#  check_mp3("http://hype.non-standard.net/serve/r/400/9673/Thalia_Zedek-Everything_Unkind.mp3")
#  return
  puts "clearing all existing filenames..."
  Track.clear_mp3_filenames
#  tracks = Track.find_by_file_type("mp3")
  tracks = Track.find_for_full_playlist(@metro_code)
  tracks.each_with_index{|track,i|
#    return if i>num_to_retrieve
    url = track.url
    begin
      filename = download_mp3(url) # 4 second timeout
      if not filename
        puts "error! (file too small?)"
        next
      end
      track.filename = filename.split("/").last
      track.status="valid"
      puts "\t\t\t\t\t\t\t\t\t\t\t\t\tSUCCESS! (#{filename})"
    rescue TimeoutError
      puts "\t\t\t\t\t\t\t\t\t\t\t\t\tfailure: Timeout"
    rescue => e
      track.status="invalid"
      puts "\t\t\t\t\t\t\t\t\t\t\t\t\tfailure: #{e}"
    end
    track.save
  }
end

def main(args)
#  ActiveRecord::Base.logger = Logger.new(STDOUT) 
  @file_root="../public/mp3s/"
  @metro_code = args[0]
  if not @metro_code
    puts "Fatal error: You must specify a metro code. Nothing was done."
    return
  end
  header "running on metro #{@metro_code}!"
  initialize_daemon(@metro_code)
  
  _update_counts=false
  _update_counts=true if !args.index("update_counts").nil?
  _check_mp3s=false
  _check_mp3s=true if !args.index("check_mp3s").nil?
  check_mp3s if _check_mp3s
  _download_mp3s=false
  _download_mp3s=true if !args.index("download_mp3s").nil?
  download_mp3s if _download_mp3s
  update_term_track_counts if _update_counts
end

# program entry point
if (!ARGV.index("help").nil?)
  puts "Tourfilter WFMU playlist crawler: downloads all wfmu playlists that have track-specific start times"
  puts "Usage: ruby check_remote_mp3s.rb first last [check_mp3s] [download_mp3s] [update_counts] [help]"
  puts "Author: chris marstall 2006-2007"
  exit
else
  puts "for usage: ruby daemon.rb help"
end
main(ARGV)


  