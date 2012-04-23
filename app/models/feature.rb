class Feature < ActiveRecord::Base
  
   unless $mode=="import_daemon"
     require "../config/environment.rb" if $mode=="daemon"
     establish_connection "shared_#{ENV['RAILS_ENV']}" 
   end
   
   has_one :match
   belongs_to :image
   belongs_to :user
  
  validates_length_of :image_url, :in=>16..255
#  validates_length_of :image_credit_url, :in=>16..255
  
  def image_url=(i)
    @image_url=i
  end
  
  def image_url
    return @image_url if @image_url
    return image.url if image
    return nil
  end
  
  def before_create
    process_image
  end

#  select features.term_text,matches.date_for_sorting from tourfilter_shared.features features,matches
#  where feature_id=features.id
#  and left(date_for_sorting,10)=left(makedate(2011,20),10)
  
  def self.recent(num,sort)
  end
  def self.on_this_day(dt)
    sql = <<-SQL
      select features.* from tourfilter_shared.features features,matches
      where feature_id=features.id
      and left(date_for_sorting,10)=left(makedate(#{dt.year},#{dt.yday}),10)
      limit 1
    SQL
    Feature.find_by_sql(sql)
  end

  def short_date
    return "#{created_at.month}/#{created_at.day}"
  end

  def before_update
    process_image if @image_url  # process new image
  end

  def process_image
    image||=Image.new
    if image.url!=image_url
      image.url = image_url
      image.problem='no'
      image.term_text=term_text
      image.save
      image.process
      self.image_id=image.id
#      self.save
    end
  end

  def render_errors
    s = "<ul>"
  	errors.each{|error|
  	  s+="<li>#{error}</li>"
    }
    s+="</ul>"
  end
end
