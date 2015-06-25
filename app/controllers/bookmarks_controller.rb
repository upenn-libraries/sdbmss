
# Define our own BookmarksController instead of using the one from
# Blacklight.
class BookmarksController < CatalogController

  include Blacklight::Bookmarks

  def export
    @bookmarks = token_or_current_or_guest_user.bookmarks
    objects = @bookmarks.map(&:document_id).map { |id| Entry.find(id).as_flat_hash }
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

end
