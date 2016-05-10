
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
    can_merge = params[:can_merge] || false
    can_link = params[:can_link] == "true"
    @bookmarks = current_user.bookmarks
    @bookmarks_sorted = {'Entry' => [], 'Source' => [], 'Manuscript' => [], 'Name' => []}
    @bookmarks.each do |bookmark|
      if @bookmarks_sorted[bookmark.document_type.to_s]
        @bookmarks_sorted[bookmark.document_type.to_s].push(bookmark)
      else
        @bookmarks_sorted[bookmark.document_type.to_s] = [bookmark]
      end
    end
    render partial: 'shared/my_bookmarks', locals: {bookmarks: @bookmarks_sorted, can_merge: can_merge, can_link: can_link}
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

  def addtag
    newtag = params[:tag]
    if newtag
      @bookmark = Bookmark.find(params[:id])
      tags = @bookmark.tags.to_s.split(',')
      if tags.include?(newtag)
        render text: 'already in tags'
      else
        render text: 'added'
        @bookmark.update({tags: (tags + [newtag]).join(',')})
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
        @bookmark.update({tags: tags.join(',')})
        render text: 'removed'
      else
        render text: 'not in tags'
      end
    end
  end

end
