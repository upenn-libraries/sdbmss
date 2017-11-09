
# Define our own BookmarksController instead of using the one from
# Blacklight.
class BookmarksController < ApplicationController

#  include Blacklight::Bookmarks
  
  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :show, :update, :destroy]

  def index
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
      elsif @bookmarks_sorted[bookmark.document_type.to_s]
        @bookmarks_sorted[bookmark.document_type.to_s].push(bookmark)
      else
        @bookmarks_sorted[bookmark.document_type.to_s] = [bookmark]
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

  def reload
    if !current_user
      render json: {error: "no_user."}
      return false
    end

    can_merge = params[:can_merge] || false
    can_link = params[:can_link] == "true"
    tag = params[:tag].blank? ? nil : params[:tag]
    #details = params[:details] || false
    details = true
    
    # something bogus here with this... when there is no tag (i.e. else)
    if tag
      @bookmarks = current_user.bookmarks.where("tags like ?", "%#{tag}%")
    else
      @bookmarks = current_user.bookmarks.all
    end
    @bookmarks_sorted = {'Entry' => [], 'Source' => [], 'Manuscript' => [], 'Name' => [], 'DericciRecord' => []}
    @bookmarks.each do |bookmark|
      if bookmark.document_type == nil
      elsif !bookmark.document
      else
        b = bookmark.for_show

        b[:details] = details_for_render(bookmark)

        if @bookmarks_sorted[bookmark.document_type.to_s]
          @bookmarks_sorted[bookmark.document_type.to_s].push(b)
        else
          @bookmarks_sorted[bookmark.document_type.to_s] = [b]
        end
      end
    end
    respond_to do |format|
      format.json {
        render json: {bookmarks: @bookmarks_sorted, bookmark_tracker: current_user.bookmark_tracker }
      }
    end
    return
    #render partial: 'shared/my_bookmarks', locals: {bookmarks: @bookmarks_sorted, can_merge: can_merge, can_link: can_link}
  end

  def create
    results = {}
    bookmark_params[:documents].each do |document|
      @bookmark = Bookmark.create({user_id: current_user.id, user_type: 'User', document_id: document[:id], document_type: document[:type]})
      if @bookmark.save
        button_html = (render_to_string partial: "delete", locals: {bookmark: @bookmark }, layout: false)
        results["#{document[:type]}_#{document[:id]}"] = { button_html: button_html }
      else
        results["#{document[:type]}_#{document[:id]}"] = { error: "Could not bookmark #{document[:id]}" }
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
      results = documents.map { |document| ["#{document.class.name}_#{document.id}", {button_html: (render_to_string partial: "add", locals: {document: document }, layout: false)}]}.to_h
      respond_to do |format|
        format.json {
          render json: { success: 'success', status_code: '200', results: results, method: 'post' } 
        }
      end
    else

    end
  end

  def addtag
    newtag = params[:tag]
    if newtag
      @bookmark = Bookmark.find(params[:id])
      tags = @bookmark.tags.to_s.split(',')
      if tags.include?(newtag)
        #render text: 'already in tags'
        render json: @bookmark.for_show
      else
        #render text: 'added'
        @bookmark.update({tags: (tags + [newtag]).join(',')})
        current_user.increment!(:bookmark_tracker)
        render json: @bookmark.for_show
      end
    end
  end

  def removetag
    tag = params[:tag]
    if tag
      @bookmark = Bookmark.find(params[:id])
      tags = @bookmark.tags.to_s.split(',')
      if tags.include?(tag)
        tags.delete(tag)
        current_user.increment!(:bookmark_tracker)
        @bookmark.update({tags: tags.join(',')})
        #render text: 'removed'
        render json: @bookmark.for_show
      else
        render json: @bookmark.for_show
        #render text: 'not in tags'
      end
    end
  end

  def details_for_render(bookmark)
    return bookmark.document.bookmark_details
  end

  def bookmark_params
    params.permit(:ids, :documents => [:id, :type])
  end

end