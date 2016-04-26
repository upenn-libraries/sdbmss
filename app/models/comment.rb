
class Comment < ActiveRecord::Base

  default_scope { where(deleted: false) }

  scope :with_associations, -> {
    includes(
      [
        :entries,
        :manuscripts,
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
  has_many :entry_comments, inverse_of: :comment
  has_many :entries, through: :entry_comments

  has_many :manuscript_comments, inverse_of: :comment
  has_many :manuscripts, through: :manuscript_comments

  validates_presence_of :comment

  accepts_nested_attributes_for :entry_comments, allow_destroy: true
  accepts_nested_attributes_for :manuscript_comments, allow_destroy: true

  include UserFields
  include HasPaperTrail
  include CreatesActivity

  searchable do
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :updated_by })
    string :created_by
    string :updated_by
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :updated_by })
    text :created_by
    text :updated_by
    text :comment
    string :comment
    integer :id
    boolean :reviewed
    boolean :is_accepted
    date :created_at
    date :updated_at
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

  # returns the model object to which this comment pertains
  def subject
    entry || manuscript
  end

end
