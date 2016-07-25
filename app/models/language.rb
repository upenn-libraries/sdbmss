class Language < ActiveRecord::Base

  default_scope { where(deleted: false) }

  has_many :entry_languages
  has_many :entries, through: :entry_languages

  include UserFields
  include ReviewedByField
  include IndexAfterUpdate
  include HasPaperTrail
  include CreatesActivity
  extend CSVExportable

  validates_presence_of :name

  searchable :unless => :deleted do
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :updated_by })
    string :created_by
    string :updated_by
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :updated_by })
    text :created_by
    text :updated_by
    text :name, :more_like_this => true
    string :name
    integer :id
    integer :entries_count
    integer :created_by_id
    date :created_at
    date :updated_at
    boolean :reviewed
  end

  def entries_to_index_on_update
    Entry.with_associations.joins(:entry_languages).where({ entry_languages: { language_id: id} })
  end

  def to_s
    name
  end

  def to_fields
    {language: name}
  end

  def public_id
    SDBMSS::IDS.get_public_id_for_model(self.class, id)
  end

  def search_result_format
    {
      id: id,
      public_id: public_id,
      name: name,
      entries_count: entries_count,
      reviewed: reviewed,
      created_by: created_by.present? ? created_by.username : "(none)",
      created_at: created_at.present? ? created_at.to_formatted_s(:long) : "",
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : ""
    }
  end

end
