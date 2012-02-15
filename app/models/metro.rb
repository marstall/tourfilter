include GeoKit::Geocoders

class Metro < ActiveRecord::Base

  establish_connection "shared" unless $mode=="daemon"

  acts_as_mappable



  #  set_table_name :metros
  has_many :places
  
  def active?
    "active"==status
  end
  
  def self.code_and_name_hash
    h = Hash.new
    Metro.find(:all).each{|metro|
      h[metro.code.downcase]=metro.code.downcase
      h[metro.name.downcase]=metro.code.downcase
      }
    return h
  end

  
=begin
SELECT *, 
  (ACOS(least(1,COS(0.334335297691973)*COS(-1.67768029542302)*COS(RADIANS(metros.lat))*COS(RADIANS(metros.lng))+
  COS(0.334335297691973)*SIN(-1.67768029542302)*COS(RADIANS(metros.lat))*SIN(RADIANS(metros.lng))+
  SIN(0.334335297691973)*SIN(RADIANS(metros.lat))))*3963.19)
AS distance 
FROM `metros` 
WHERE (metros.lat>13.3732073858564 AND metros.lat<24.9387956141436 
        AND metros.lng>-102.243263488743 AND metros.lng<-90.004737111257 
        AND (ACOS(least(1,COS(0.334335297691973)*COS(-1.67768029542302)*COS(RADIANS(metros.lat))*COS(RADIANS(metros.lng))+
        COS(0.334335297691973)*SIN(-1.67768029542302)*COS(RADIANS(metros.lat))*SIN(RADIANS(metros.lng))+
        SIN(0.334335297691973)*SIN(RADIANS(metros.lat))))*3963.19)
       <= 400
 ) 
 ORDER BY distance
=end

  def nearby_metros(miles=400)
    return nil unless self.lat and self.lng
     puts "within 30 miles of #{self.lat}/#{self.lng}"
    Metro.find(:all, :origin => [self.lat,self.lng],:within=>miles,:order=>'distance')
  end
  
  def Metro.nearby_metros(lat,lng)
    metro=Metro.new
    metro.lat=lat
    metro.lng=lng
    return metro.nearby_metros
  end
  
  def self.count_all_places_all_metros
    Metro.count_by_sql("select sum(num_places) from metros where status='active'")
  end
  
  def self.count_all_metros
    Metro.count_by_sql("select count(*) from metros where status='active'")
  end
  
  def self.find_all
    Metro.find_by_sql("select * from metros order by name asc")
  end

  def self.find_all_active
    Metro.find_by_sql("select * from metros where status='active' order by name asc")
  end

  def self.find_all_curated_and_active
    Metro.find_by_sql("select * from metros where status='active' and curated=true order by name asc")
  end

  def self.all_active_for_select(all_option=false,lowercase=false)
    metros=find_by_sql("select name, code from metros where status='active' order by name asc");
    select_metros=Array.new
    all_string="All"
    all_string.downcase! if lowercase
    select_metros<<[all_string,""] if all_option 
    metros.each{|metro|
      metro_name = metro.name
      metro_name.downcase! if lowercase
      select_metros<<[metro_name,metro.code]
    }
    select_metros
  end
  
  def self.allNames
    metros = find_by_sql("select name from metros where code not like '%search%' order by name asc");
    metro_names=[]
    metros.each { |metro|
      metro_names<<metro.name
    }
    return metro_names
  end

end
