require 'set'

class Manuscript < ActiveRecord::Base

  has_many :entry_manuscripts, inverse_of: :manuscript
  has_many :entries, through: :entry_manuscripts
  #has_many :manuscript_comments
  has_many :comments, as: :commentable
  has_many :linked_entries, -> { where entry_manuscripts: { relation_type: EntryManuscript::TYPE_RELATION_IS } }, source: :entry, through: :entry_manuscripts

  has_many :bookmarks, as: :document, dependent: :destroy

  accepts_nested_attributes_for :entry_manuscripts, allow_destroy: true

  include Watchable
  include UserFields
  #include IndexAfterUpdate
  #include HasPaperTrail
  # do this manually, since we want to create versions when record is touched
  has_paper_trail

  include CreatesActivity
  extend SolrSearchable

  include TellBunny

  # searchable!

  searchable do
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
    text :name
    string :name
    text :url
    string :url
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

  def to_citation
    now = DateTime.now.to_formatted_s(:date_mla)
    "Schoenberg Database of Manuscripts. The Schoenberg Institute for Manuscript Studies, University of Pennsylvania Libraries. Web. #{now}: #{public_id}."
  end

  def all_titles
    @manuscript_titles = Set.new

    #if name
    #  @manuscript_titles.add(name)
    if entries.count > 0
      entries.each do |entry|
        if entry.entry_titles.count > 0
          entry.entry_titles.each do |title|
            if title.present?
              @manuscript_titles.add(title.common_title)
              @manuscript_titles.add(title.title)
            end
          end
        end
      end
    end
    @manuscript_titles.delete(nil)
  end

  def to_i
    id
  end

  def to_s
    all_titles.to_a.join(",")[0..50]
  end

  def bookmark_details
    results = {
      titles: all_titles.to_a.join(", "),
      location: location,
      url: url,
      entries_count: entries_count
    }
    (results.select { |k, v| !v.blank? }).transform_keys{ |key| key.to_s.humanize }
  end

  def search_result_format
    {
      id: id,
      name: name,
      location: location,
      url: url,
      entries_count: entries_count,
      reviewed: reviewed,
      created_by: created_by.present? ? created_by.username : "(none)",
      created_at: created_at.present? ? created_at.to_formatted_s(:long) : "",
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : ""
    }
  end

  def self.fields
    super + [["Last Known Location", "location"]]
  end

  def to_rdf
    map = {
      model_class: "manuscripts",
      id: id,
      fields: {}
    }

    map[:fields][:name] = format_triple_object name,         :string
    map[:fields][:location] = format_triple_object location, :string
    map[:fields][:url] = format_triple_object url,           :string

    map
  end

end
