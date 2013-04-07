
class Note < ActiveRecord::Base
  belongs_to :source, :counter_cache => true
  validates_presence_of :source_id
  
  belongs_to :user
  
  def self.content_columns
    %w{ user_id action message source_id updated_at}
  end
  
  
end
