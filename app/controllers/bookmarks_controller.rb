
# Define our own BookmarksController instead of using the one from
# Blacklight.
class BookmarksController < ApplicationController

#  include Blacklight::Bookmarks
  
  before_action :authenticate_user!, only: [:index, :new, :create, :edit, :show, :update, :destroy]

  def index
    # fix me: not logged in
    @tag = params[:tag].blank? ? nil : params[:tag]
    # something bogus here with this... when there is no tag (i.e. else)
    if @tag
      @bookmarks = current_user.bookmarks.where("tags like ?", "%#{@tag}%")
    else
      @bookmarks = current_user.bookmarks.all
    end
    @bookmarks_sorted = {'Entry' => [], 'Source' => [], 'Manuscript' => [], 'Name' => []}
    @bookmarks.each do |bookmark|
      if bookmark.document.nil?
      elsif bookmark.document_type == nil
      elsif @bookmarks_sorted[bookmark.document_type.to_s]
        @bookmarks_sorted[bookmark.document_type.to_s].push(bookmark.for_show)
      else
        @bookmarks_sorted[bookmark.document_type.to_s] = [bookmark.for_show]
      end
    end
  end

  def export
    @bookmarks = token_or_current_or_guest_user.bookmarks
    # FIX ME: needs to be polymorphic
#    objects = @bookmarks.map(&:document_id).map { |id| Entry.find(id).as_flat_hash }
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
    @bookmarks_sorted = {'Entry' => [], 'Source' => [], 'Manuscript' => [], 'Name' => []}
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

  def show
    # fix me: make sure bookmark belongs to current_user
    if params[:id] && Bookmark.exists?(params[:id].to_i)
      @bookmark = Bookmark.find(params[:id])
      @name = @bookmark.document_type.to_s
      render layout: false
    end
  end

  def new
    if Bookmark.where({user: current_user, document_id: params[:document_id], document_type: params[:document_type]}).count > 0
      flash[:error] = "That record is already bookmarked."
      render json: {error: "already bookmarked"}
    else
      @bookmark = Bookmark.create({user: current_user, document_id: params[:document_id], document_type: params[:document_type]})
      @bookmark.save!
      flash[:message] = "Bookmark created."
      b = @bookmark.for_show
      b[:details] = details_for_render(@bookmark)
      current_user.increment!(:bookmark_tracker)
      render json: b
    end
    #redirect_to :back
  end

  def destroy
    @bookmark = Bookmark.find(params[:id])
    @bookmark.destroy!
    flash[:message] = "Bookmark removed."
    current_user.increment!(:bookmark_tracker)
    render text: 'destroyed'
    #redirect_to :back
  end

  # fix me: why are we checking for bookmarks when not logged in?
  def check
    if current_user
      render json: {bookmark_tracker: current_user.bookmark_tracker}
    else
      render json: {error: "no_user"}
    end
  end

  def delete_all
    ids = params[:id]
    if !ids
    elsif ids.kind_of? Array
      ids.each do |id|
        Bookmark.find(id).destroy
      end
    else
      Bookmark.find(ids).destroy
    end
    current_user.increment!(:bookmark_tracker)
    redirect_to bookmarks_path
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
  
end
