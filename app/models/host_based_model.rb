class HostBasedModel < ActiveRecord::Base
  cattr_accessor :metro_code
#  establish_connection("#{RAILS_ENV}_westernmass")
end