require 'uri'

class PagesController < ApplicationController

  load_and_authorize_resource :only => [:index, :edit, :create, :update, :destroy]

  def index
    @pages = Page.all
    @page = Page.new
  end

  def create
    if (uploaded_io = page_params[:filename])
      p = Page.new(filename: uploaded_io.original_filename, name: page_params[:name], category: page_params[:category])
      if uploaded_io.content_type == "text/html" && p.ext == "html"
        File.open(Rails.root.join('public', "#{p.location}", uploaded_io.original_filename), 'wb') do |file|
          file.write(sanitize uploaded_io.read)
        end
        p.save
        if p.errors.count > 0
          flash[:error] = p.errors.full_messages.join(", ")
        end

      elsif uploaded_io.content_type == "application/pdf" && p.ext == "pdf"
        File.open(Rails.root.join('public', "#{p.location}", uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end          
        p.save      
        if p.errors.count > 0
          flash[:error] = p.errors.full_messages.join(", ")
        end        
      else
        flash[:error] = "Warning: Unpermitted file type."
      end
      redirect_to pages_path
    end
  end

  def show
    @page = Page.find_by(name: params[:name])
    if @page.nil?
      render_404
    elsif @page.ext == "pdf"
      redirect_to "/#{@page.location}/#{URI.encode @page.filename}"
    else
      @filecontents = nil
      File.open(Rails.root.join('public', "#{@page.location}", @page.filename), 'r') do |file|
        @filecontents = sanitize(file.read)
      end 
    end
  end

  def edit
    @page = Page.find_by(name: params[:name])
    @filecontents = nil
    if @page.ext == "pdf"
    else
      File.open(Rails.root.join('public', "#{@page.location}", @page.filename), 'r') do |file|
        @filecontents = sanitize(file.read)
      end
    end
  end

  def update
    @page = Page.find(params[:name])
    if (uploaded_io = page_params[:filename])
      if uploaded_io.content_type == "text/html" && @page.ext == "html"
        File.open(Rails.root.join('public', "#{@page.location}", uploaded_io.original_filename), 'wb') do |file|
          file.write(sanitize uploaded_io.read)
        end
      elsif uploaded_io.content_type == "application/pdf" && @page.ext == "pdf"
        File.open(Rails.root.join('public', "#{@page.location}", uploaded_io.original_filename), 'wb') do |file|
          file.write(uploaded_io.read)
        end          
      else
        flash[:error] = "Warning: Unpermitted file type."
      end
      @page.update(filename: uploaded_io.original_filename, name: page_params[:name])
    elsif params[:contents]
      File.open(Rails.root.join('public', "#{@page.location}", @page.filename), 'wb') do |file|
        file.write(sanitize params[:contents])
      end
      @page.update(name: page_params[:name])
    else
      @page.update(name: page_params[:name])
    end
    
    if @page.errors.count > 0
      flash[:error] = @page.errors.full_messages.join(", ")
    end
    
    redirect_to pages_path
  end

  def destroy
    @page = Page.find_by(name: params[:name])
    if File.delete(Rails.root.join('public', "#{@page.location}", @page.filename))
      @page.destroy!
      flash[:error] = "#{@page.name} successfully deleted."
    end
    redirect_to pages_path
  end

  def preview
    if params[:content]
      render json: {result: (sanitize(params[:content]))}
    else
      render json: {error: "nothing sent to preview"}
    end
  end

  private

  def page_params
    params.require(:page).permit(:filename, :name, :content, :category)
  end

  def sanitize(original)
    ActionController::Base.helpers.sanitize original, tags: %w(figcaption figure img pre p table td tr th tbody li ul ol span div code b i br strong em a legend h1 h2 h3 h4 h5), attributes: %w(src href class style target)
  end

end