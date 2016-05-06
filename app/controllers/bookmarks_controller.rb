
# Define our own BookmarksController instead of using the one from
# Blacklight.
class BookmarksController < CatalogController

  include Blacklight::Bookmarks

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
    @bookmarks = current_user.bookmarks
    @bookmarks_sorted = {}
    @bookmarks.each do |bookmark|
      if @bookmarks_sorted[bookmark.document_type]
        @bookmarks_sorted[bookmark.document_type].push(bookmark)
      else
        @bookmarks_sorted[bookmark.document_type] = [bookmark]
      end
    end
    render partial: 'shared/my_bookmarks', locals: {bookmarks: @bookmarks_sorted}
  end

  def new
    if Bookmark.where({user: current_user, document_id: params[:document_id], document_type: params[:document_type]}).count > 0
      flash[:error] = "That record is already bookmarked."
    else
      @bookmark = Bookmark.create({user: current_user, document_id: params[:document_id], document_type: params[:document_type]})
      @bookmark.save!
      flash[:message] = "Bookmark created."
    end
    redirect_to :back
  end

  def destroy
    @bookmark = Bookmark.find(params[:id])
    @bookmark.destroy!
    flash[:message] = "Bookmark removed."
    render text: 'destroyed'
    #redirect_to :back
  end

end
