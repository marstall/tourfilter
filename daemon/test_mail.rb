require "rubygems"
require "../config/environment.rb"

TestMailer::deliver_test("chris@psychoastronomy.org","test")
puts "done."