class SourcesController < ApplicationController

  before_filter :must_be_admin

  def index
    list
    render :action => 'list'
  end

  # GETs should be safe (see http://www.w3.org/2001/tag/doc/whenToUseGet.html)
  verify :method => :post, :only => [ :destroy, :create, :update ],
         :redirect_to => { :action => :list }

  def search
    @source=Source.new
    @source["field"]=params[:source][:field]
    @sources=Source.find_by_search_term(params[:search],params[:source][:field])
    render(:action=>'list')
  end

  def list
    @source_pages, @sources = paginate :sources, :per_page => 100, :order=>"id desc"
  end

  def show
    @source = Source.find(params[:id])
  end

  def new
    @source = Source.new
  end

  def create
    @source = Source.new(params[:source])
    if @source.save
      flash[:notice] = 'Source was successfully created.'
      redirect_to :action => 'list'
    else
      render :action => 'new'
    end
  end

  def edit
    @source = Source.find(params[:id])
  end

  def update
    @source = Source.find(params[:id])
    if @source.update_attributes(params[:source])
      flash[:notice] = 'Source was successfully updated.'
      redirect_to :action => 'show', :id => @source
    else
      render :action => 'edit'
    end
  end

  def destroy
    Source.find(params[:id]).destroy
    redirect_to :action => 'list'
  end
end
