class Itunes
  @username=nil

  def initialize(logger,username=nil)
    @logger = logger
    @username = username
  end
  
  
  def log (s)
    if @logger!=nil
      @logger.info s 
    else
      puts s
    end
  end
  
  def library_path
    "#{RAILS_ROOT}/itunes/#{@username}_library.xml"
  end
  
  def extract_artists_from_user_file
    text=File.read(self.library_path)
    self.extract_artists_from_file(text)
  end
   
  def extract_artists_from_file(text)
    # first identify whether what format this file is in. Supported formats are currently:
    #     - iTunes Library
    #     - iTunes Songlist
    # then pass to the appropriate file
    
    # is this an itunes library file?
    # algorithm: look for the string "<?xml" at the beginning of the first 10 lines
    i=0
    text.split(/[\n\r]+/).each { |line|
      i+=1
      break if i>10
      #log line
      if line =~/\<\?xml/ 
        log("[ITUNES] iTunes Library detected, parsing ...")
        return extract_artists_from_itunes_library(text)
      end
    }
    # ok, not an itunes library file so presume it's a songlist file ...

    log("[ITUNES] iTunes Songlist detected, parsing ...")
     return extract_artists_from_itunes_songlist(text)
  end
  
  def extract_artists_from_itunes_songlist(text)
    # text = text.gsub(/\^@/,"") # collapse all consecutive whitespace into a single space
    artists = Hash.new
    text.split(/\r+/).each { |line|
      if line =~ /MPEG/
        line =~ /^([\w ]+)\t([\w ]+)\t/    
        log $2 if $2!=nil
        artists[$2]="" if $2!=nil
      end
    }
    artists    
  end
  
  def excluded?(name)
    return true if name !~ /^[a-zA-Z0-9 ]+$/ # don't import anything with special characters
    return true if name =~/\sfeat/i # don't import anything with "feat." "Featuring" etc.'
    return false
  end

  def extract_artists_from_itunes_library(xml)
    # parse through xml, find all <name> elements that
    # have a value of "Artist" and retrieve the next "String" value,
    # which will be the name of the artist. Ex:
    # plist/dict/dict/dict:
    # <key>Artist</key><string>Mahmoud Ahmed</string>    
    artists = Hash.new
    xml.split(/\n+/).each { |line|
      if line =~ /^\s*<key>Artist<\/key>/
        line =~ /(<string>)(.*)(<\/string>)/    
        artist_name = $2
        
        artists[artist_name]="" unless excluded?(artist_name)
        log $2        
      end
    }
    a=Array.new
    artists.each_key{|key|a<<key}
    a
  end
end
  
def test
  file_path = ARGV[0]
  file = File.new(file_path, "r")
  itunes = ITunes.new(nil)
  artists = itunes.extract_artists_from_file(file.read)
  artists.each_key { |artist|
  puts artist
  }
end

#test
