class PagesController < ApplicationController

  load_and_authorize_resource :only => [:index, :edit, :create, :update, :destroy]

  def index
    @pages = Page.all
    @page = Page.new
  end

  def create
    uploaded_io = page_params[:filename]
    ActiveRecord::Base.transaction do
      File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
        file.write(uploaded_io.read)
        p = Page.create(filename: uploaded_io.original_filename, name: page_params[:name])
        if p.errors.count > 0
          flash[:error] = p.errors.full_messages.join(", ")
        end
        redirect_to pages_path
      end
    end
  end

  def show
    @page = Page.find_by(name: params[:name])
    if @page.ext == "pdf"
      redirect_to "/uploads/#{@page.filename}"
    else
      render file: "/public/uploads/#{@page.filename}"
    end
  end

  def edit
    @page = Page.find_by(name: params[:name])
  end

  def update
    @page = Page.find(params[:name])
    ActiveRecord::Base.transaction do
      if (uploaded_io = page_params[:filename])
        File.open(Rails.root.join('public', 'uploads', uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end
        @page.update(filename: uploaded_io.original_filename, name: page_params[:name])
      else
        @page.update(name: page_params[:name])
      end
      if @page.errors.count > 0
        flash[:error] = @page.errors.full_messages.join(", ")
      end
    end
    redirect_to pages_path
  end

  def destroy
    page = Page.find_by(name: params[:name])
    if File.delete(Rails.root.join('public', 'uploads', page.filename))
      page.destroy!
    end
    redirect_to pages_path
  end

  private

  def page_params
    params.require(:page).permit(:filename, :name)
  end

end