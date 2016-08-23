class Comment < ActiveRecord::Base

  default_scope { where(deleted: false) }

  scope :with_associations, -> {
    includes(
      [
        :entries,
        :manuscripts,
        :sources,
        :names,
        :created_by
      ]
    )
  }

  # returns the comments on all Entries created by passed-in User
  scope :with_entries_belonging_to, ->(user) { joins(:entries).where(entries: { created_by: user }).order(created_at: :desc) }

  # inverse_of is required for accepts_nested_attributes_for to
  # populate the FK to the Comment object. See these pages:
  #
  # https://github.com/rails/rails/issues/20451
  # http://viget.com/extend/exploring-the-inverse-of-option-on-rails-model-associations

  belongs_to :commentable, polymorphic: true
  has_many :replies

  has_many :entry_comments, inverse_of: :comment
  has_many :entries, through: :entry_comments

  has_many :manuscript_comments, inverse_of: :comment
  has_many :manuscripts, through: :manuscript_comments

  has_many :source_comments, inverse_of: :comment
  has_many :sources, through: :source_comments

  has_many :name_comments, inverse_of: :comment
  has_many :names, through: :name_comments

  validates_presence_of :comment

  accepts_nested_attributes_for :entry_comments, allow_destroy: true
  accepts_nested_attributes_for :manuscript_comments, allow_destroy: true
  accepts_nested_attributes_for :source_comments, allow_destroy: true
  accepts_nested_attributes_for :name_comments, allow_destroy: true

  include UserFields
  include HasPaperTrail
  include CreatesActivity
  extend CSVExportable

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
    join(:id, :target => Source, :type => :integer, :join => { :from => :id, :to => :source})
    integer :source
    join(:id, :target => Name, :type => :integer, :join => { :from => :id, :to => :name})
    integer :name
    join(:id, :target => Entry, :type => :integer, :join => { :from => :id, :to => :entry})
    integer :entry
    join(:id, :target => Manuscript, :type => :integer, :join => { :from => :id, :to => :manuscript})
    integer :manuscript
  end

  def entry
    entries.first
  end

  def manuscript
    manuscripts.first
  end

  def source
    sources.first
  end

  def name
    names.first
  end

  # returns the model object to which this comment pertains
  def subject
    if entry
      entry
    elsif manuscript
      manuscript
    elsif source
      source
    elsif name
      name
    end
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
      #entry_id: entry.try(:id),
      #manuscript_id: manuscript.try(:id),
      #source_id: source.try(:id),      
      #name_id: name.try(:id),      
      comment: comment,
      #is_correction: is_correction,
      is_accepted: is_accepted,
      reviewed: reviewed,
      created_by: created_by.username,
      created_at: created_at.to_formatted_s(:date_and_time),
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : ""
    }
  end
end
