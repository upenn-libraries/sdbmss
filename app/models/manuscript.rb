require 'set'

class Manuscript < ActiveRecord::Base

  has_many :entry_manuscripts
  has_many :entries, through: :entry_manuscripts
  has_many :manuscript_comments
  has_many :linked_entries, -> { where entry_manuscripts: { relation_type: EntryManuscript::TYPE_RELATION_IS } }, source: :entry, through: :entry_manuscripts

  accepts_nested_attributes_for :entry_manuscripts, allow_destroy: true

  include UserFields

  # returns all the Event objects associated with all the entries for this MS
  def get_unique_provenance
    # TODO: how to make sure they're "unique" since these records are
    # complex? maybe we don't do that.
    Event.provenance.where(entry_id: linked_entries)
  end

  def public_id
    return "SDBM_MS_" + id.to_s
  end

  # returns an array of entry IDs
  def entry_candidates
    candidate_ids = Set.new
    linked_entries.each do |entry|
      SDBMSS::SimilarEntries.new(entry).each do |similar_entry|
        entry = similar_entry[:entry]
        if entry.get_manuscript.blank?
          candidate_ids.add entry.id
        end
      end
    end
    candidate_ids
  end

end
