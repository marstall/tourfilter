class Track < ActiveRecord::Base
  
   unless $mode=="import_daemon"
     require "../config/environment.rb" if $mode=="daemon"
     establish_connection "shared_#{ENV['RAILS_ENV']}" 
   end

  def shared_term
	SharedTerm.find_by_text(term_text)
  end 
  def Track.unique_by_term_text(band_name,file_type='mp3')
    sql="select * from tracks where status<>'invalid' and file_type=? and band_name = ?  or band_name = ? group by track_name asc"
    Track.find_by_sql([sql,file_type,"#{band_name}","the #{band_name}"])
  end

  def Track.count_by_term_text(band_name,file_type='mp3')
    sql="select count(distinct track_name) from tracks where status<>'invalid' and file_type=? and band_name like ?"
    Track.count_by_sql([sql,file_type,"%#{band_name}"])
  end

  def self.count_by_term_text(term_text,file_type='mp3')
    sql="select count(*) from tracks where status<>'invalid' and file_type=? and term_text=?"
    Track.count_by_sql([sql,file_type,term_text])
  end

=begin
  def self.find_by_term(term, file_type='mp3',source_reference=nil,num=5)
    sql="select * from tracks where status<>'invalid' and file_type=? and term_text=? "
    sql+=" and source_reference=? " if source_reference
    sql+=" limit ?"
    params=[sql,file_type,term.text]
    params<<source_reference if source_reference
    params<<num
    find_by_sql(params)
  end
=end
  
  def self.find_by_term(term, file_type='mp3',source_reference=nil,num=5,locally_cached_only=false)
    sql="select * from tracks where status<>'invalid' and file_type=? and term_text=? "
    sql+=" and source_reference=? " if source_reference
    sql+=" and locally_cached='true'" if locally_cached_only
    sql+=" limit ?"
    term_text=term.text if term.is_a? Term
    params=[sql,file_type,term_text]
    params<<source_reference if source_reference
    params<<num
    find_by_sql(params)
  end

  def self.find_by_file_type(file_type)
    sql = "select * from tracks where file_type=? order by term_text asc"
    Track.find_by_sql([sql,file_type])
  end
  
  def self.find_for_full_playlist(metro_code)
    sql =  " select tracks.* from tracks,tourfilter_#{metro_code}.matches matches, tourfilter_#{metro_code}.terms terms"
    sql += " where tracks.term_text=terms.text and terms.id=matches.term_id "
    sql += " and tracks.status<>'invalid' "
    sql += " and matches.status='notified' and matches.time_status='future' "
    sql += " group by term_text order by matches.id desc "
    Track.find_by_sql(sql)
  end

  # by_date_added|by_concert_date|random|by_club_name|by_num_trackers
  def self.find_all_with_filename(metro_code,sort="by_date_added")
    sort="by_date_added" if !sort or sort.strip==""
    sql =  " select tracks.* "
    sql += " ,count(*) num_trackers " if sort=="by_num_trackers"
    sql +=  " from tracks,tourfilter_#{metro_code}.terms,tourfilter_#{metro_code}.matches matches"
    sql += " ,terms_users " if sort=="by_num_trackers"
    sql += " ,terms_users,pages,places " if sort=="by_club_name"
    sql += " where tracks.term_text=terms.text and terms.id=matches.term_id "
    sql += " and matches.page_id=pages.id and pages.place_id=places.id " if sort=="by_club_name"
    sql += " and matches.status='notified' and matches.time_status='future' "
    sql += " and tracks.status<>'invalid' "
    sql += " and terms_users.term_id=terms.id " if sort=="by_num_trackers"
    sql += " and filename is not null group by term_id "
    sql += " order by num_trackers desc " if sort=="by_num_trackers"
    sql += " order by matches.date_for_sorting asc" if sort=="by_concert_date"
    sql += " order by matches.id desc" if sort=="by_date_added"
    sql += " order by places.name " if sort=="by_club_name"
    logger.info("SQL "+sql)
    tracks = Track.find_by_sql(sql)
    if sort=="random"
      already_used=Hash.new
      new_array=Array.new
      existing_size=tracks.size
      while new_array.size<existing_size
        random_existing_track = tracks[ rand(existing_size)]
        if not already_used[random_existing_track.id]
          already_used[random_existing_track.id]=true
          new_array<<random_existing_track
        end
      end
      return new_array
    end
    tracks
  end
  
  def self.random_mp3
    Track.find(6474053)
  end
  
  def self.clear_mp3_filenames
    Track.update_all("filename=NULL","file_type='mp3'")
  end
end
