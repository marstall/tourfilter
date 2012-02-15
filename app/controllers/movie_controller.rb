class MovieController < ApplicationController  

  include YoutubeHelper


  def edit_movie
    @movie = Movie.find_by_id(params[:id])
    if request.post?
      if params[:cancel]
        flash[:notice]="Cancelled. No action was taken!"
        redirect_to params[:referer]
      elsif params[:query]
        @query=params[:query]
        @referer=params[:referer]
        @xml = search_youtube(@query,params[:page]||1,10)
      elsif params[:cancel]
        flash[:notice]="Cancelled. No action was taken!"
        redirect_to params[:referer]
      else
        @query=@movie.title
        @movie.youtube_id = params[:youtube_id]
        @movie.save
        if params[:youtube_id!]!="-1"
        #  flash[:notice]="You have updated the trailer for #{@movie.title} successfully. Thanks!"
        else
        #  flash[:notice]="You have removed the trailer for #{@movie.title} successfully. Thanks!"
        end
        expire_home_page
        MovieEditedMailer::deliver_movie_edited(@movie) if @movie
        redirect_to params[:referer]
      end
    else
      @referer = request.env['HTTP_REFERER']
      @query=@movie.title
      @xml = search_youtube_for_trailers(@movie,params[:page]||1,10,true,true)
    end
  end

  def edit
    edit_movie
    render(:action=>"edit_movie")
  end
  
  def play_youtube_video
    render(:layout=>false)
  end

end