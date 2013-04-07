class Tagging < ActiveRecord::Base

  unless $mode=="import_daemon"
    require "../config/environment.rb" if $mode=="daemon"
    establish_connection "shared_#{ENV['RAILS_ENV']}" 
    @cnn='shared'
  end
  belongs_to :tag
  has_one :imported_event
end
