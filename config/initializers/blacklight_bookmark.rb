Bookmark.class_eval do
  def document
    document_type.find(document_id)
  end

  def to_s
    document.to_s
  end

end