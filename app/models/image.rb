
class Image < ActiveRecord::Base
  include UrlFetcher
  begin
    include Magick 
  rescue
    puts "could not find RMagick, continuing ..."
  end


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
    Term.make_url_text(self.term_text)
  end

  def small_url
    "http://s3.amazonaws.com/tourfilter.com/#{url_term_text}_s_s.jpg"
  end

  def medium_url
    "http://s3.amazonaws.com/tourfilter.com/#{url_term_text}_r_m.jpg"
    #"/images/default_term.jpg"
  end
  
  def medium_square_url
    "http://s3.amazonaws.com/tourfilter.com/#{url_term_text}_s_m.jpg"
  end

  def large_url
    "http://s3.amazonaws.com/tourfilter.com/#{url_term_text}_r_l.jpg"
  end

  def large_square_url
    "http://s3.amazonaws.com/tourfilter.com/#{url_term_text}_s_l.jpg"
  end

  def make_size(img,x,y)
    require 'RMagick' 
    
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

  def process
    require 'RMagick' 
    term_text = Term.make_url_text(self.term_text)
    # download jpg from urls
#    puts "downloading #{self.url} ..."
    filename = download_jpg(self.url)
#    puts filename
    # create 3 scaled versions -s, m & l
    puts "creating 6 scaled copies ..."
    file = Magick::Image.read(filename).first
    s_s = make_size(file,100,100)
    s_m = make_size(file,200,200)
    s_l = make_size(file,400,400)

    # ratio = width/x
    # shrink width to x,
    # then crop height to y
    width = file.columns
    puts width
    
    r_s = make_size(file,100,200)
    r_m = make_size(file,200,250)
    r_l = make_size(file,300,400)

    s_s.write("#{term_text}_s_s.jpg")
    s_m.write("#{term_text}_s_m.jpg")
    s_l.write("#{term_text}_s_l.jpg")
    r_s.write("#{term_text}_r_s.jpg")
    r_m.write("#{term_text}_r_m.jpg")
    r_l.write("#{term_text}_r_l.jpg")
    # upload to S3
    S3.copy_to_s3("#{term_text}_s_s.jpg")
    S3.copy_to_s3("#{term_text}_s_m.jpg")
    S3.copy_to_s3("#{term_text}_s_l.jpg")
    S3.copy_to_s3("#{term_text}_r_s.jpg")
    S3.copy_to_s3("#{term_text}_r_m.jpg")
    S3.copy_to_s3("#{term_text}_r_l.jpg")
#    puts "http://s3.amazonaws.com/tourfilter.com/#{term_text}_s.jpg"
#    puts "http://s3.amazonaws.com/tourfilter.com/#{term_text}_m.jpg"
#    puts "http://s3.amazonaws.com/tourfilter.com/#{term_text}_l.jpg"
    # mark record as processed
#    puts "marking record as saved ... "    
    self.processed_at=DateTime.now
    self.save
  end
  
  def self.find_unprocessed_images
    self.find_by_sql("select * from images where problem='no' and processed_at is null")
  end
  
end