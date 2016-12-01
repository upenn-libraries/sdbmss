# I dropped the old comment join tables manually, so if there's ever a problem with migrations and these new tables springing up, that would be why

class Comment < ActiveRecord::Base

  include Notified

  #default_scope { where(deleted: false) }

  scope :with_associations, -> {
    includes(
      [
        :created_by
      ]
    )
  }

  # returns the comments on all Entries created by passed-in User
  
  # inverse_of is required for accepts_nested_attributes_for to
  # populate the FK to the Comment object. See these pages:
  #
  # https://github.com/rails/rails/issues/20451
  # http://viget.com/extend/exploring-the-inverse-of-option-on-rails-model-associations

  belongs_to :commentable, polymorphic: true
  has_many :replies

  validates_presence_of :comment

  include UserFields
  include HasPaperTrail
  include CreatesActivity
  extend SolrSearchable

  searchable :unless => :deleted do
    string :created_by do
      created_by ? created_by.username : ""
    end
    string :updated_by do
      updated_by ? updated_by.username : ""
    end
    text :created_by do
      created_by ? created_by.username : ""
    end
    text :updated_by do
      updated_by ? updated_by.username: ""
    end
    string :commentable_type
    integer :commentable_id
    text :comment
    string :comment
    integer :id
    boolean :reviewed
    boolean :is_accepted
    date :created_at
    date :updated_at
  end

  def self.fields
    fields = super.unshift("comment")
    fields.delete("name")
    fields
  end

  def self.filters
    super + ["commentable_id", "commentable_type"]
  end

  def search_result_format
    {
      id: id,
      commentable_url: "/#{commentable_type.to_s.pluralize.underscore}/#{commentable_id}", 
      commentable_id: commentable ? commentable.public_id : nil,
      comment: comment,
      is_accepted: is_accepted,
      reviewed: reviewed,
      created_by: created_by.username,
      created_at: created_at.to_formatted_s(:date_and_time),
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : ""
    }
  end

  def preview
    %(
      <blockquote>#{comment.at(0..100)}#{comment.length > 100 ? '...' : ''}</blockquote>
    )
  end

end
