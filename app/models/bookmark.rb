class Bookmark < ActiveRecord::Base

  belongs_to :user
  belongs_to :document, polymorphic: true

  validates :user_id, presence: true
  validates :document_type, presence: true
  validates :document_id, presence: true

  validates :user_id, uniqueness: { 
    scope: [:document_id, :document_type],
    message: "you can only bookmark a record once"
  }

  delegate :public_id, to: :document, prefix: true, allow_nil: true

  if Blacklight::Utils.needs_attr_accessible?
    attr_accessible :id, :document_id, :document_type, :title
  end

  def to_s
    document.to_s
  end

  def for_show
    {
      id: id, 
      document_id: document_id, 
      document_type: document_type.to_s, 
      tags: tags.to_s.split(','), 
      link: "/#{document_type.to_s.underscore.pluralize}/#{document_id}", 
      public_id: document.public_id, 
      show: document.to_s,
      updated_at: updated_at.to_s
    }
  end
  
  def document_type
    (super.constantize if defined?(super)) || default_document_type
  end

end