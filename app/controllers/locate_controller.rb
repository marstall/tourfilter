class LocateController < ApplicationController  

  def locate
    set_metro_code("")
    @metro_code=nil
    @not_in_a_city=true
  end
  
  def set_metro_drop_down
    lat = params[:lat]
    lng = params[:lng]
    # now do a nearness calculation in the metros table
  end
end