require 'set'

class Manuscript < ActiveRecord::Base

  has_many :entry_manuscripts, inverse_of: :manuscript
  has_many :entries, through: :entry_manuscripts
  has_many :manuscript_comments
  has_many :comments, through: :manuscript_comments
  has_many :linked_entries, -> { where entry_manuscripts: { relation_type: EntryManuscript::TYPE_RELATION_IS } }, source: :entry, through: :entry_manuscripts

  accepts_nested_attributes_for :entry_manuscripts, allow_destroy: true

  include UserFields
  include IndexAfterUpdate
  include HasPaperTrail
  include CreatesActivity

  # searchable!
  
  searchable do
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :string, :join => { :from => :username, :to => :updated_by })
    string :created_by
    string :updated_by
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :created_by })
    join(:username,  :target => User, :type => :text, :join => { :from => :username, :to => :updated_by })
    text :created_by
    text :updated_by
    text :name
    string :name
    text :location
    string :location
    integer :id
    boolean :reviewed
    integer :entries_count
    date :created_at
    date :updated_at
  end

  # Fetches the Provenance records for ALL entries for this MS, and
  # returns an array of 2-item arrays of name string and array of
  # provenance records containing that name. ie:
  #
  # [
  #  [ 'Joe', [ Provenance #1, Provenance #2 ] ],
  #  [ 'Bob', [ Provenance #2, Provenance #3 ] ],
  # ]
  def all_provenance_grouped_by_name
    groups = Hash.new
    Provenance.where(entry_id: linked_entries).order(start_date: :desc, entry_id: :desc).each do |provenance|
      name = provenance.provenance_agent.present? ? provenance.provenance_agent.name : provenance.observed_name
      if name.present?
        if groups[name] == nil
          groups[name] = []
        end
        groups[name] << provenance
      end
    end
    groups.sort { |a,b| a[0].downcase <=> b[0].downcase }
  end

  def public_id
    return SDBMSS::IDS.get_public_id_for_model(self.class, id)
  end

  def display_value
    public_id + (name.present? ? ": " + name : "")
  end

  # returns the most recent updated_at timestamp, as an integer, of
  # this Manuscript AND all its pertinent associations.
  def cumulative_updated_at
    SDBMSS::Util.cumulative_updated_at(self, [:entry_manuscripts])
  end

  # returns an array of entry IDs
  def entry_candidates
    candidate_ids = Set.new
    linked_entries.each do |entry|
      SDBMSS::SimilarEntries.new(entry).each do |similar_entry|
        entry = similar_entry[:entry]
        if entry.manuscript.blank?
          candidate_ids.add entry.id
        end
      end
    end
    candidate_ids
  end

  def entries_to_index_on_update
    Entry.with_associations.joins(:entry_manuscripts).where({ entry_manuscripts: { manuscript_id: id} })
  end

  def to_citation
    now = DateTime.now.to_formatted_s(:date_mla)
    "Schoenberg Database of Manuscripts. The Schoenberg Institute for Manuscript Studies, University of Pennsylvania Libraries. Web. #{now}: #{public_id}."
  end

end
