class PlaceImage < ActiveRecord::Base

  belongs_to :page
  belongs_to :place
  
  def img_html(passed_width=nil,passed_height=nil)
    width=nil and height=nil if passed_width or passed_height
    "<img src='#{url}' width='#{passed_width||width||""}' height='#{passed_height||height||""}' title='#{alt_text}'>"
  end
end
