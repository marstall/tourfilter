module BandsHelper
  @brick_count=0
  def brick_style
    @first||=true
    @brick_count||=0
    base_red=140
    base_blue=238
    base_green=238
    blue=base_blue#-(@brick_count*10)
    red=base_red+(@brick_count*20)
    green=base_green#-(@brick_count*10)
    @brick_count+=1
    ret = "background-color:rgb(#{red},#{green},#{blue})"
    ret = "#{ret};margin-top:0em" if @first
    @first=false
    ret
  end
end
