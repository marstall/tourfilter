class Showing < ActiveRecord::Base
  belongs_to :movie
  belongs_to :place
  belongs_to :page
  
  def self.future_showings(num_days,offset=0)
    num_days=Integer(num_days)
    find_by_sql <<-SQL
      select showings.* from showings,movies
      where date>=left(adddate(now(),interval #{offset} day),10)
      and date<=left(adddate(now(),interval #{num_days-1} day),10)
      and showings.movie_id = movies.id
      order by showings.date asc,movies.title asc  
    SQL
  end
  
  def self.find_for_day(date,place=nil)
    place_sql=" and places.id=#{place.id} " if place
    find_by_sql <<-SQL
      select showings.* from showings,movies,places
      where date= '#{date.year}-#{date.month}-#{date.day}' 
      and movies.id=showings.movie_id
      and places.id=showings.place_id   
      #{place_sql}
      order by places.sequence asc, movies.title asc
    SQL
  end

  def self.output(h)
    return unless h
    h.each_key{|key|
      puts "#{key}: #{h[key].to_s[0...100]}" 
    }
  end

  def output(h)
    self.output(h)
  end

  def self.add_new_by_hash(page,h)
    output(h)
    # first see if there is a movie with this title and year - if not, create it
    if h[:year] and not h[:year].nil?
      movie = Movie.find_by_title_and_year(h[:title],h[:year])
    else
      movie = Movie.find_by_title(h[:title],:order=>"year desc")
#      movie = movies[0] if movies and not movies.empty?
    end
#    puts "synopsis in showing (#{h[:title]}): #{h[:synopsis]}"
    movie = Movie.new if not movie
    movie.title=h[:title] unless movie.title
    movie.year=h[:year] unless movie.year
    movie.basic_facts=h[:basic_facts] unless movie.basic_facts and h[:basic_facts] and movie.basic_facts.size>h[:basic_facts].size
#    movie.synopsis=h[:synopsis] unless movie.basic_facts and h[:synopsis] and movie.synopsis.size>h[:synopsis].size
    movie.synopsis=h[:synopsis] unless movie.synopsis
    movie.save
    
    # if there is an image_url, create a new image record pointing to this movie
    if h[:image_url]
      image = Image.new
      image.movie_id=movie.id
      image.url = h[:image_url]
      image.source = h[:source]
      image.save
    end
    
    # if there is an existing showtime for this movie on this day, modify it. otherwise, create a new one.
    if h[:showtime_string]
      showing = Showing.find_by_movie_id_and_date(movie.id,h[:date])
    else
      showing = Showing.find_by_movie_id_and_date_and_time(movie.id,h[:date],h[:time])
    end
    if not showing
#      puts h[:date_string]
      if h[:date_string]
        h[:date]= DateTime.parse(h[:date_string])
      end
#      puts h[:date]
      showing=Showing.new
      showing.date=h[:date]
      showing.time_string=h[:showtime_string]
      showing.time=h[:time]
      showing.url=h[:detail_link]
      showing.movie_id=movie.id
      showing.page_id=page.id
      showing.place_id=page.place.id
      showing.save
    end
  end
    
    
end
