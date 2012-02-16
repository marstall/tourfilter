require "rubygems"
require_gem "activerecord"
require "../app/models/term.rb"

ActiveRecord::Base.establish_connection(
  :adapter=>"mysql",
  :host=>"127.0.0.1",
  :username=>'chris',
  :password=>'chris',
  :database=> "tourfilter_#{metro_code}")

_terms=Term.find_all
terms=Hash.new
_terms.each{|term|terms[_terms.text]=true}
terms_found=Hash.new
accompaniers=Hash.new
text = STDIN.read
lines = text.split("\n")
for line in lines do
  words = line.scan " "
  0.upto words.size {|n|
    0.upto words.size-n {|i|
      j=words.size-i
      potential_term=words[n..j]
      puts potential_term
      next unless terms[potential_term]
      # found a match
      terms_found[potential_term]=Hash.new
      # get accompanying terms
      
      }
  }
   