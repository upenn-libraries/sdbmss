#Bookmark.class_eval do
#  def document
#    document_type.find(document_id)
#  end
#
#  def to_s
#    document.to_s
#  end
#
#  def for_show
#    {id: id, document_id: document_id, document_type: document_type.to_s, tags: tags.to_s.split(','), link: "/#{document_type.to_s.underscore.pluralize}/#{document_id}", public_id: document.public_id, show: document.to_s }
#  end
#
#end