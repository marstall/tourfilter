
class Source < ActiveRecord::Base

  has_many :notes, :order=>"created_at desc"
  belongs_to :user
  
#  file_column :image, :magick => { :geometry => "100x24" }
  
  def self.content_columns
    %w{ name category status locale updated_at notes_count}
  end
  
  def self.find_by_search_term(search_term,field)
    search_term="%#{search_term}%"
    find_by_sql(["select * from sources where #{field} like ?",search_term])
  end
  
  def self.find_featured(feature_level)
    find_by_sql(["select * from sources where feature=? order by mention_date desc",feature_level])
  end
  
  def image_url
    "/source/image/"
  end

#  @scaffold_columns=[
#  Scaffold::ScaffoldColumn.new(self, { :name => "name" }),
#  Scaffold::ScaffoldColumn.new(self, { :name => "category" }),
#  Scaffold::ScaffoldColumn.new(self, { :name => "status" }),
#  Scaffold::ScaffoldColumn.new(self, { :name => "locale" }),
#  Scaffold::ScaffoldColumn.new(self, { :name => "updated_at" }),
#  Scaffold::ScaffoldColumn.new(self, { :name => "# notes" ,
#    :eval => "source.notes.size"})
#    ]
end
