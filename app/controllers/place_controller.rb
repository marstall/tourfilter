class PlaceController < ApplicationController

  before_filter :must_be_admin,:except=>"images"
  
  def metros
    Metro.allNames
  end
  
  def index
    list
    render :action => 'list'
  end

  def list
    params[:direction] ||= 'asc'
    params[:order] ||= 'working_at'
    order = params[:order] || 'name'
    direction = params[:direction]
    if params[:query]
      @places = Place.find_by_sql("select * from places where name like '%#{params[:query]}%' or notes like '%#{params[:query]}%' order by #{order} #{direction}")
    else
      @places = Place.find(:all,:order=>order)
    end
  end

  def show
    @place = Place.find(params[:id])
  end
  
  def show_cached_page
    @page = Page.find(params[:id])
  end

  def new
    @place = Place.new
  end

  def create
    @place = Place.new(params[:place])
    if @place.save
      flash[:notice] = 'Place was successfully created.'
      @place.generate_urls
      error=@place.fetch_urls
      if error
        flash[:notice] = error
      else
        flash[:notice] = 'Place was successfully updated.'
      end
    end
    render :controller=>"place", :action => 'edit'
  end

  def edit
    @place = Place.find(params[:id])
  end

  def just_save(redirect=false)
    if @place.update_attributes(params[:place])
        flash[:notice] = 'Place was successfully updated.'
        if redirect
          redirect_to params[:return_url]||"/place"
        else
          redirect_to :controller=>"place", :action => 'edit', :id => @place
        end
    end
  end
  
  def images
    name = params[:id]
    if name
      places = Place.find_by_sql("select id,name from places where name like \"%#{name}%\"")
      @place_images = PlaceImage.find_by_sql("select * from place_images where term_text is not null and place_id in (\"#{places.collect{|place|place.id}.join(',')}\")")
    else
      @place_images = PlaceImage.find_by_sql("select * from place_images where term_text is not null")
    end
  end

  def send_mail
    new_place=Place.new
    new_place.attributes= params[:place]
    PlaceMailer::deliver_place_update(@youser,@metro,@metro_code,@place,new_place)
  end

  def update
    @place = Place.find(params[:id])
    @place.edited_at=Time.now
    @place.working_at=Time.now if params[:working]
    send_mail if params[:email_admins]
    if params[:mark_all_pages_as_past]
      @place.mark_all_pages_as_past
      @place.delete_template_urls
      params[:pages_as_text]=""
      flash[:notice]="ALL PAGES SUCCESSFULLY MARKED AS PAST - NOW ADD SOME NEW ONES OR ELSE THE PLACE WILL NOT EXIST ANYMORE"
      redirect_to :controller=>"place", :action => 'edit', :id => @place
      return
    end
    return just_save if params[:just_save]
    return just_save(true) if params[:just_save_and_return]
    logger.info("updating place #{@place}")
    if @place.update_attributes(params[:place])
      if @place.errors and not @place.errors.empty?
        logger.info("ERROR SAVING PLACE!")
        error_string="ERROR!!"
        error_string+=String(@place.errors.collect{|error|"#{error.to_s.sub(/is invalid/,'')}<br>"})
        flash[:error]=error_string
        redirect_to :controller=>"place", :action => 'edit', :id => @place
        return
      end
      logger.info("generating urls for place #{@place}")
      @place.generate_urls
      logger.info("crawling urls for place #{@place}")
      @place=Place.find(@place.id) # reload pages ...
      error=@place.fetch_urls
      if error
        logger.info("error crawling urls for place #{@place}")
        flash[:notice] = "ERROR IN FETCHING URLS!<BR>#{error}"
      else
        logger.info("redirecting to edit/#{@place}")
        flash[:notice] = 'Place was successfully updated.'
      end
      redirect_to :controller=>"place", :action => 'edit', :id => @place
    end
  end

  def destroy
    Place.find(params[:id]).destroy
    redirect_to :controller=>"place", :action => 'list'
  end
end
