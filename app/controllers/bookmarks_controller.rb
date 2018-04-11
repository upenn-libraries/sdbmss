
# Define our own BookmarksController instead of using the one from
# Blacklight.
class BookmarksController < ApplicationController

  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :show, :update, :destroy]

  def index
    respond_to do |format|
      format.html {}
      format.json do
        @tag = params[:tag].blank? ? nil : params[:tag]
        if @tag
          @bookmarks = current_user.bookmarks.where("tags like ?", "%#{@tag}%")
        else
          @bookmarks = current_user.bookmarks.all
        end
        @bookmarks_sorted = {'Entry' => [], 'Source' => [], 'Manuscript' => [], 'Name' => [], 'DericciRecord' => []}
        @bookmarks.each do |bookmark|
          if bookmark.document.nil?
          elsif bookmark.document_type == nil
          else
            if @bookmarks_sorted[bookmark.document_type.to_s].nil?
              @bookmarks_sorted[bookmark.document_type.to_s] = []
            end
            b = bookmark.for_show

            b[:details] = details_for_render(bookmark)
            @bookmarks_sorted[bookmark.document_type.to_s].push(b)
          end
        end
        render json: {bookmarks: @bookmarks_sorted, bookmark_tracker: current_user.bookmark_tracker }        
      end
    end
  end

  def export
    @bookmarks = token_or_current_or_guest_user.bookmarks
    objects = @bookmarks.map { |bookmark| bookmark.document.as_flat_hash }
    respond_to do |format|
      format.csv {
        headers = objects.first.keys
        formatter = Proc.new do |object|
          headers.map { |key| object[key] }
        end
        render csv: objects,
               filename: "bookmarks.csv",
               headers: headers,
               format: formatter
      }
    end
  end

  def create
    results = {}
    bookmark_params[:documents].each do |document|
      @bookmark = Bookmark.create({user_id: current_user.id, user_type: 'User', document_id: document[:id], document_type: document[:type]})
      if @bookmark.save
        button_html = (render_to_string partial: "delete", locals: {bookmark: @bookmark }, layout: false)
        results["Bookmark_#{document[:type]}_#{document[:id]}"] = { button_html: button_html }
      else
        results["Bookmark_#{document[:type]}_#{document[:id]}"] = { error: "Could not bookmark #{document[:id]}" }
      end
      #flash[:message] = "Bookmark created."
    end

    respond_to do |format|
      format.json {
        render json: { success: 'success', status_code: '200', results: results }
      }
    end
  end

  def destroy
    bookmarks = Bookmark.includes(:document).where(id: params[:ids])
    documents = bookmarks.map(&:document)
    if bookmarks.destroy_all
      results = documents.map { |document| ["Bookmark_#{document.class.name}_#{document.id}", {button_html: (render_to_string partial: "add", locals: {document: document }, layout: false)}]}.to_h
      respond_to do |format|
        format.json {
          render json: { success: 'success', status_code: '200', results: results, method: 'post' } 
        }
      end
    else
    end
  end

  def update
    @bookmark = Bookmark.find(params[:id])
    if @bookmark
      @bookmark.update(bookmark_params)
    end
    render json: @bookmark.for_show    
  end

  def details_for_render(bookmark)
    return bookmark.document.bookmark_details
  end

  def bookmark_params
    params.permit(:ids, :tags, :documents => [:id, :type])
  end

end