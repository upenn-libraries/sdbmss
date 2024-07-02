
# Note that we treat this as a "first-class" entity, similar to Entry
# or Source, even though it is a join record. This should probably be
# renamed to something like EntryLink.
class EntryManuscript < ActiveRecord::Base
  belongs_to :entry
  belongs_to :manuscript, counter_cache: :entries_count

  validates_presence_of :entry
  validates_presence_of :manuscript
  validates_presence_of :relation_type

  TYPE_RELATION_IS = 'is'
  TYPE_RELATION_PARTIAL = 'partial'
  TYPE_RELATION_POSSIBLE = 'possible'

  include UserFields
  include HasPaperTrail
  include CreatesActivity
  include Ratable

  include TellBunny

  extend SolrSearchable

  def create_activity(action_name, current_user, transaction_id)
    activity = super
    em_activity = EntryManuscriptActivity.new(
      activity: activity,
      entry_id: entry_id,
      manuscript_id: manuscript_id,
      transaction_id: transaction_id
    )
    success = em_activity.save
    if !success
      Rails.logger.error "Error saving EntryManuscriptActivity object: #{em_activity.errors.messages}"
    end
    activity
  end

  searchable do
    integer :id
    integer :manuscript_id
    integer :entry_id
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
    date :created_at
    date :updated_at
    string :relation_type
    boolean :reviewed
  end

  def self.fields
    []
  end

  def public_id
    id.to_s
  end

  def dispute_reasons
    ["Incorrectly linked", "Other"]
  end

  def search_result_format
    {
      id: id,
      entry_id: entry_id,
      manuscript_id: manuscript_id,
      relation_type: relation_type,
      reviewed: reviewed,
      created_by: created_by.present? ? created_by.username : "(none)",
      created_at: created_at.present? ? created_at.to_formatted_s(:long) : "",
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : ""
    }
  end

  def to_rdf
    map = {
      model_class: "entry_manuscripts",
      id: id,
      fields: {}
    }

    map[:fields][:entry_id]      = format_triple_object entry_id,      :uri,   'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:manuscript_id] = format_triple_object manuscript_id, :uri,   'https://sdbm.library.upenn.edu/manuscripts/'
    map[:fields][:relation_type] = format_triple_object relation_type, :string

    map
  end

end