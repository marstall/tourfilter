class TermWord < ActiveRecord::Base
  establish_connection "shared" unless $mode=="daemon"
end
