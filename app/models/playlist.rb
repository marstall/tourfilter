require "../app/models/track.rb"

class Playlist < ActiveRecord::Base
  
  def find_and_save_tracks
    # first retrieve just the table
    #body =~ /\<table.+\/table\>/
    #puts body
    puts "body is #{body.size} bytes"
    body =~ /<table.*?>(.*)<\/table>/m
    #puts body
    return if not $&
    puts " ... found table"
    line_matches = $1.scan /<tr>(.*?)<\/tr>/m
    puts "  ... found #{line_matches.size} rows in table"
    line_matches.each{|line_match|
      line = line_match[0]
      #puts line
      #check to see that the final cell has at least one url w/starttime in it
      cell_matches = line.scan /<td.*?>(.*?)<\/td>/m
      #puts "    ... found #{cell_matches.size} cells in row"
      if cell_matches.empty?
        puts "        (skipping)"
        next
      end
      last_cell = cell_matches.last[0] 

      # ok we presumably have a good line here, so process all cells
      # artist: presume that cell1 contains the artist
      # track name: if there are more than 2 columns, presume that cell 2 contains the track name
      #   otherwise, make the track name "unknown"
      # album: if there are more than 3 columns, presume that cell 3 contains the album name
      # track information: urls, starttime, type -- there can be multiple track types in the cell
      # each of these must result in a different row in the table.
      #puts last_cell
      matches = last_cell.scan /(listen.(ram|m3u)\?show=(\d{3,5})(?:&archive=(\d{3,5}))?&starttime=(0?[0-9]):([0-9]{2}):([0-9]{2}))/
      puts "couldn't find audio link in row, skipping:\n#{last_cell}" if matches.empty?
      matches.each{|match|
        track_url = match[0]
        #puts url
        file_type = match[1]
        _show_id = match[2]
        archive_id = match[3]
        hours = match[4].sub(/(^0(\d))/,'\2') #remove trailing zeros
        minutes = match[5].sub(/(^0(\d))/,'\2') #remove trailing zeros
        seconds = match[6].sub(/(^0(\d))/,'\2') #remove trailing zeros
        offset=Integer(hours)*3600+Integer(minutes)*60+Integer(seconds)
        #puts "url:\t#{match[0]}"
        #puts "type:\t#{match[1]}"
        #puts "show_id:\t#{match[2]}"
        #puts "archive_id:\t#{match[3]}"
        #puts "hours:"+hours
        #puts "minutes:"+minutes
        #puts "seconds:"+seconds
        # determine band name: get the first cell and strip out random stuff
        first_cell = cell_matches.first[0]
        first_cell =~/>(.+?)</
        band_name=$1
        # determine track name
        if cell_matches.size>2
          second_cell = cell_matches[1][0]
          second_cell =~/>(.+?)</m
          if $1
            track_name=$1.strip
          else
            track_name="unknown"
          end
        end
        # determine album name
        if cell_matches.size>3
          third_cell = cell_matches[2][0]
          third_cell =~/>(.+?)</m
          album_name=$1.strip if $1
        end
        # see if there is a year in the line someplace
        line =~ /(?:19|20)\d\d/
        year=$&
        puts "#{track_url}\t\t#{year}\t\t#{band_name}\t\t#{track_name}\t\t#{album_name}"
        track = Track.new
        track.band_name=band_name
        track.track_name=track_name
        track.album_name=album_name
        track.url = track_url
        track.file_type=file_type
        track.offset=offset
        track.playlist_id=id
        track.playlist_url=url
        track.archive_id=archive_id
        track.show_id=_show_id
        track.year=year
        track.save
        }
      }
  end

end
