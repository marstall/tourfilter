class Movie < ActiveRecord::Base
  has_many :showings
  
  def last_date(place)
    return unless place
    sql = <<-SQL
      select * from showings
      where place_id=#{place.id}
      and movie_id=#{id}
      and date is not null
      order by time desc
    SQL
    showings = Showing.find_by_sql(sql)
    puts showings.inspect
    date = showings.first.date
    return [date,showings.size]
  end

  def delete_videos
    Video.delete_all(["movie_id=?",id])
  end

  def delete_auto_chosen_videos
    Video.delete_all(["movie_id=? and rank<>-1",id])
  end
  
  def select_video(youtube_id)
    self.video_selected = video.id
    self.save
  end

  def video
    sql = <<-SQL
      select * from videos where movie_id=#{id} order by rank asc limit 1
      SQL
    videos=Movie.find_by_sql sql
    return videos[0] if videos and not videos.empty?
  end

  def image
    sql = <<-SQL
      select * from images where movie_id=#{id} and location='local' limit 1
      SQL
    images=Movie.find_by_sql sql
    return images[0] if images and not images.empty?
  end
end
