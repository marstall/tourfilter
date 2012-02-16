#require '~/tourfilter/config/environment.rb'
#require "geoip"
require '~/tourfilter/config/environment.rb'
require '/Users/chris/.gem/ruby/1.8/gems/geoip-1.0.0/lib/geoip.rb'

geoip = GeoIP.new("#{RAILS_ROOT}/maxmind/GeoLiteCity.dat")
File.open("searches.log", "r") do |file|

file.each_line{|line|
  elems = line.split(" ")
  ip_address = elems[1]
  line=~/\"GET(.+)HTTP\/1.1/
  url = $1
  c = geoip.city(ip_address)
  city =  c.to_hash[:city_name]
  state =  c.to_hash[:region_name]
#  puts "#{ip_address} #{city}, #{state} #{url}"
  puts c.to_hash.inspect
}
# ... process the file

end
=begin

  def geolocate_
    require ‘geoip’
    c = GeoIP.new("~/maxmind/GeoLiteCity.dat").city()
    => [“www.nokia.com”, “147.243.3.83”, 69, “FI”, “FIN”, “Finland”, “EU”]
    c.country_code3
    => “FIN”
    c.to_hash
    => {:country_code3=>"FIN", :country_name=>"Finland", :continent_code=>"EU",
    :request=>"www.nokia.com", :country_code=>69, :country_code2=>"FI", :ip=>"147.243.3.83"}


    c = GeoIP.new(‘GeoLiteCity.dat’).city(‘github.com’)
    => [“github.com”, “207.97.227.239”, “US”, “USA”, “United States”, “NA”, “CA”,
    “San Francisco”, “94110”, 37.7484, -122.4156, 807, 415, “America/Los_Angeles”]
    >> c.longitude
    => -122.4156
    >> c.timezone
    => “America/Los_Angeles”
  end
=end