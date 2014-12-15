class Manuscript < ActiveRecord::Base

  has_many :entry_manuscripts
  has_many :entries, through: :entry_manuscripts

  # returns all the Event objects associated with all the entries for this MS
  def get_unique_provenance
    # TODO: how to make sure they're "unique" since these records are
    # complex? maybe we don't do that.
    Event.provenance.where(entry_id: entry_manuscripts.map { |em| em.entry_id } )
  end

end
