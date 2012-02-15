if $mode=='import_daemon'
  require 'mechanize'
  require "../config/environment.rb" 

  include GeoKit::Geocoders
end

class Venue < ActiveRecord::Base

   establish_connection "shared" unless $mode=="import_daemon"

  has_many :imported_events

  def self.add_or_find(name,city,state,source)
    venue=Venue.find_by_name_and_state(name,state)
    venue=Venue.find_by_name_and_state("the #{name}",state) if not venue
    venue=Venue.find_by_name_and_state(name.sub(/^the\s/i,"").strip,state) if not venue
    if not venue
      if name.strip.empty? or city.strip.empty? or state.strip.empty?
        puts "venue data missing, skipping..."
        return nil
      end            
      venue=Venue.new
      venue.name=name
      venue.city=city
      venue.state=state
      venue.source=source
      venue.save
      puts "added venue #{name}."
    else
      #puts "already added venue #{name}, not adding again."
    end
    venue
  end

  def metro_code
    mv = MetrosVenue.find_by_venue_id(id)
    return "" if mv.nil?
    return mv.metro_code
  end
  
  def fetch_parse_and_save
  end  

  if $mode=='import_daemon'
    acts_as_mappable

    def initialize_cache
      mkdir("/tmp/tourfilter") rescue nil
    end
  
    def clear_cache
      rm_rf("/tmp/tourfilter")
    end
  
    def self.find_near_metro_by_geocoding(metro,miles=50)
        return nil unless metro.lat and metro.lng
  #      puts "within 30 miles of #{metro.lat}/#{metro.lng}"
        self.find(:all, :origin => [metro.lat,metro.lng],:within=>miles)
    end
    
    def geocode 
      if address and address.size>0
        full_address = "#{address},#{city},#{state}"
      else
        full_address = "#{city},#{state}"
      end
      full_address="#{full_address}, #{zipcode}" if zipcode
      puts "[#{self.name}] #{full_address}"
      res = MultiGeocoder.geocode(full_address)
      if not res.nil?
        self.zipcode=res.zip
        self.lat=res.lat
        self.lng=res.lng
        self.geo_precision=res.precision
        self.corrected_address=res.full_address
        self.save
      else
        puts "nil response"
      end
      puts "#{self.zipcode} #{self.lat} #{self.lng}"    
    end
  end

end

  


