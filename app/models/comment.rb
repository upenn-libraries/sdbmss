# FIX ME: this class is in an intermediate state; until it is pushed to production and comments 
# moved over to new polymorphic method, have to keep old structure as well!

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
  #scope :with_entries_belonging_to, ->(user) { joins(:entries).where(entries: { created_by: user }).order(created_at: :desc) }

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
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :updated_by })
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :updated_by })
    text :created_by
    text :updated_by
    string :created_by
    string :updated_by
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
