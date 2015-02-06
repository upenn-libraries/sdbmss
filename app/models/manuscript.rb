class Manuscript < ActiveRecord::Base

  has_many :entry_manuscripts
  has_many :entries, through: :entry_manuscripts
  has_many :linked_entries, -> { where entry_manuscripts: { relation_type: EntryManuscript::TYPE_RELATION_IS } }, source: :entry, through: :entry_manuscripts

  include UserFields

  # returns all the Event objects associated with all the entries for this MS
  def get_unique_provenance
    # TODO: how to make sure they're "unique" since these records are
    # complex? maybe we don't do that.
    Event.provenance.where(entry_id: linked_entries)
  end

  def get_public_id
    return "SDBM_MS_" + id.to_s
  end

end
