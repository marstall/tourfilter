#!/usr/bin/env ruby
text = STDIN.read
lines = text.split("\n")
i = 1
filters=ARGV+%w(google q=)
for line in lines do
  filters.each{|filter| next unless line =~ /#{filter}/}
  matches = line.scan(/q\=(.+?)\&/).each{|query|
   next if query[0].strip=="t"
	query=query[0].gsub /\%../, " "
	puts query.gsub "+"," " 
	 
  }
end

