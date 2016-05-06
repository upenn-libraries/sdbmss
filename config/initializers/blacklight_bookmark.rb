Bookmark.class_eval do
  def document
    document_type.find(document_id)
  end
end