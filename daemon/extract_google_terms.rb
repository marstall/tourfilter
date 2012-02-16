#!/usr/bin/env ruby
text = STDIN.read
lines = text.split("\n")
i = 1
if ARGV.size>0
  filters=ARGV
else
  filters=%w(google q=)
  end
for line in lines do
  filters.each{|filter| next unless line =~ /#{filter}/}
  matches = line.scan(/(?:q\=)[^+]+(?:\&)/).each{|word[0] |
    puts word
  }
end
