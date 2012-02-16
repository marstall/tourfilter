require "rubygems"
require_gem "activerecord"
require "../app/models/term.rb"
require "../app/models/term_word.rb"

ActiveRecord::Base.establish_connection(
  :adapter=>"mysql",
  :host=>"127.0.0.1",
  :username=>'chris',
  :password=>'chris',
  :database=> "tourfilter_boston")


Term.find_all.each{|term|
  puts term.text
  term.text.split.each{|word|
    term_word = TermWord.new
    term_word.term_id=term.id
    term_word.created_at=term.created_at
    term_word.word=word
    term_word.save
    }
  }
   