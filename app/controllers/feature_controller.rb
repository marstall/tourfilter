class FeatureController < ApplicationController
  
  include QuickAuthModule

  def feature
    @full_width_footer=true
    begin
      @match=Match.find(params[:match_id])
    rescue
      render(:inline=>"can't find that id!")
    end
  end

  def flyers
    @featured_matches=Match.current_with_feature(-1,"rand()")
    render :layout=>'new_layout'
  end
  

  

end
