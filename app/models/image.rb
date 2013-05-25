require 'RMagick'

class Image < ActiveRecord::Base
  include UrlFetcher


  belongs_to :imported_event
  has_many :features

  establish_connection "shared_#{ENV['RAILS_ENV']}" unless $mode=="daemon"

  def self.random
    sql = <<-SQL
      select * from images where id=(select round(rand()*max(id)) from images where processed_at is not null and problem<>'yes');   
    SQL
    image=self.find_by_sql(sql) while not image or image.empty?
    return image[0]
  end
  
  def height_proportional_to_width(width)
    
  end

  def url_term_text
    term_text
#    Term.make_url_text(self.term_text)
  end

  def Image.filename(id,shape,size)
    "#{id}_#{shape}_#{size}.jpg"
  end

  def small_url
    "http://s3.amazonaws.com/tourfilter.com/#{imported_event_id}_s_s.jpg"
  end

  def medium_url
    "http://s3.amazonaws.com/tourfilter.com/#{imported_event_id}_r_m.jpg"
    #"/images/default_term.jpg"
  end
  
  def medium_square_url
    "http://s3.amazonaws.com/tourfilter.com/#{imported_event_id}_s_m.jpg"
  end

  def large_url
    "http://s3.amazonaws.com/tourfilter.com/#{imported_event_id}_r_l.jpg"
  end

  def large_square_url
    "http://s3.amazonaws.com/tourfilter.com/#{imported_event_id}_s_l.jpg"
  end

  def make_size(img,x,y)
    require 'RMagick' 
    
    img.auto_orient! # read exif data an orient appropriately
    
    
    # shrink x first, by appropriate amount.
    # then crop to y
    original_x = img.columns.to_f
    original_y = img.rows.to_f
    x=x.to_f
    y=y.to_f
    puts "original x: #{original_x}"
    puts "original y: #{original_y}"
    puts "x: #{x}"
    if x==y
      if original_x<original_y
        if original_x>x
          x_shrink_ratio = x/original_x
          puts "x_shrink_ratio: #{x_shrink_ratio}"
          puts "shrinking ... "
          img = img.scale(x_shrink_ratio)
          puts "new img width: #{img.columns}"
          puts "new img height: #{img.rows}"
        end
        if img.rows>y
          puts "cropping ... "
          img  = img.crop(0,0,img.columns,y)
          puts "new img width: #{img.columns}"
          puts "new img height: #{img.rows}"
        end
      else
        if original_y>y
          y_shrink_ratio = y/original_y
          puts "y_shrink_ratio: #{y_shrink_ratio}"
          puts "shrinking ... "
          img = img.scale(y_shrink_ratio)
          puts "new img width: #{img.columns}"
          puts "new img height: #{img.rows}"
        end
        if img.columns>x
          puts "cropping ... "
          img  = img.crop(0,0,x,img.rows)
          puts "new img width: #{img.columns}"
          puts "new img height: #{img.rows}"
        end
      end
    else
      if original_x>x
        x_shrink_ratio = x/original_x
        puts "x_shrink_ratio: #{x_shrink_ratio}"
        puts "shrinking ... "
        img = img.scale(x_shrink_ratio)
        puts "new img width: #{img.columns}"
        puts "new img height: #{img.rows}"
      end
      if img.rows>y
        puts "cropping ... "
        img  = img.crop(0,0,img.columns,y)
        puts "new img width: #{img.columns}"
        puts "new img height: #{img.rows}"
      end
    end
    return img
  end

  def make_width(img,x)
    
    # shrink x first, by appropriate amount.
    # then crop to y
    original_x = img.columns.to_f
    x=x.to_f
    puts "original x: #{original_x}"
    puts "x: #{x}"
    x_shrink_ratio = x/original_x
    puts "x_shrink_ratio: #{x_shrink_ratio}"
    puts "shrinking ... "
    img = img.scale(x_shrink_ratio)
    puts "new img width: #{img.columns}"
    puts "new img height: #{img.rows}"
    return img
  end


  def extract_geolocation(img)
    return unless img
    img_lat = img.get_exif_by_entry('GPSLatitude')[0][1].split(', ') rescue nil
    img_lng = img.get_exif_by_entry('GPSLongitude')[0][1].split(', ') rescue nil

    lat_ref = img.get_exif_by_entry('GPSLatitudeRef')[0][1] rescue nil
    lng_ref = img.get_exif_by_entry('GPSLongitudeRef')[0][1] rescue nil

    return unless img_lat && img_lng && lat_ref && lng_ref

    latitude = to_frac(img_lat[0]) + (to_frac(img_lat[1])/60) + (to_frac(img_lat[2])/3600)
    longitude = to_frac(img_lng[0]) + (to_frac(img_lng[1])/60) + (to_frac(img_lng[2])/3600)

    latitude = latitude * -1 if lat_ref == 'S'  # (N is +, S is -)
    longitude = longitude * -1 if lng_ref == 'W'   # (W is -, E is +)

    self.lat = latitude
    self.lng = longitude
  end

  def extract_other_exif(img)
    return unless img
    self.make = img.get_exif_by_entry('Make')
    self.camera_model_name = img.get_exif_by_entry('CameraModelName')
    self.exif = img.get_exif_by_entry
  end

  def to_frac(strng)
    numerator, denominator = strng.split('/').map(&:to_f)
    denominator ||= 1
    numerator/denominator
  end
  
    
  def process(detect_dupes=true)
#    term_text = Term.make_url_text(self.term_text)
    # download jpg from urls
    puts "+++ downloading #{self.url} ..."
    filename = download_jpg(self.url)
    self.md5 = Digest::MD5.file(filename).hexdigest
    duplicate_image = self.class.find_by_md5(md5) # find dupe image, crap out if one is found
    if duplicate_image 
      return duplicate_image 
    end

    
#    puts filename
    # create 3 scaled versions -s, m & l
    puts "creating 6 scaled copies ..."
    file = Magick::Image.read(filename).first
    extract_geolocation(file)
    extract_other_exif(file)
    s_s = make_size(file,100,100)
    s_m = make_size(file,200,200)
    s_l = make_size(file,400,400)

    r_s = make_size(file,100,200)
    r_m = make_size(file,400,800)
    r_l = make_size(file,800,1600)
    

    # ratio = width/x
    # shrink width to x,
    # then crop height to y
    self.width = file.columns
    self.height = file.rows
    
    self.orientation = self.width > self.height ? "landscape" : "portrait"
    

#    n_s = make_width(file,100)
#    n_m = make_size(file,400)
#    n_l = make_size(file,800)
    

    s_s.write("#{imported_event_id}_s_s.jpg")
    s_m.write("#{imported_event_id}_s_m.jpg")
    s_l.write("#{imported_event_id}_s_l.jpg")
    r_s.write("#{imported_event_id}_r_s.jpg")
    r_m.write("#{imported_event_id}_r_m.jpg")
    r_l.write("#{imported_event_id}_r_l.jpg")
#    n_s.write("#{imported_event_id}_r_s.jpg")
#    n_m.write("#{imported_event_id}_r_m.jpg")
#    n_l.write("#{imported_event_id}_r_l.jpg")
    # upload to S3
    S3.copy_to_s3("#{imported_event_id}_s_s.jpg")
    S3.copy_to_s3("#{imported_event_id}_s_m.jpg")
    S3.copy_to_s3("#{imported_event_id}_s_l.jpg")
    S3.copy_to_s3("#{imported_event_id}_r_s.jpg")
    S3.copy_to_s3("#{imported_event_id}_r_m.jpg")
    S3.copy_to_s3("#{imported_event_id}_r_l.jpg")
#    S3.copy_to_s3("#{imported_event_id}_n_s.jpg")
#    S3.copy_to_s3("#{imported_event_id}_n_m.jpg")
#    S3.copy_to_s3("#{imported_event_id}_n_l.jpg")
#    puts "http://s3.amazonaws.com/tourfilter.com/#{term_text}_s.jpg"
#    puts "http://s3.amazonaws.com/tourfilter.com/#{term_text}_m.jpg"
#    puts "http://s3.amazonaws.com/tourfilter.com/#{term_text}_l.jpg"
    # mark record as processed
#    puts "marking record as saved ... "    
    self.processed_at=DateTime.now
    self.save
    return false
  end
  
  def self.find_unprocessed_images
    self.find_by_sql("select * from images where problem='no' and processed_at is null")
  end
  
end