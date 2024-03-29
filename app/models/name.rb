
require 'set'

# This is the place where all the names of people and institutions,
# associated with Entries in various ways (as authors, artists,
# scribes, provenance agents, source agents), are stored.
#
# Flags such as is_author, is_artist, etc indicate the context in
# which the name was created; autocomplete widgets use this role when
# searching so they get the types of names they are interested in.
# IMPORTANT: Note that the is_provenance_agent flag covers any name
# created for Provenance, SourceAgent, and SaleAgent records.
#
# There are a number of counter_cache fields on this model, which
# usually get updated when there are changes to related data, but NOT
# always. In particular, note that #update_all skips callbacks.
class Name < ActiveRecord::Base

  include UserFields
  include Watchable
  include ReviewedByField
  include IndexAfterUpdate
  include HasPaperTrail
  include CreatesActivity
  include Notified

  include Ratable

  include TellBunny

  extend SolrSearchable

  default_scope { where(deleted: false) }

  belongs_to :entry

  belongs_to :reviewed_by, :class_name => 'User'

  #belongs_to :associated_place, :class_name => 'Place'

  has_many :name_places, :dependent => :destroy
  has_many :places, -> {distinct}, through: :name_places

  has_many :bookmarks, as: :document, dependent: :destroy

  has_many :entry_artists, foreign_key: "artist_id"
  has_many :artist_entries, -> {distinct},  through: :entry_artists, source: :entry

  has_many :entry_authors, foreign_key: "author_id"
  has_many :author_entries, -> {distinct},  through: :entry_authors, source: :entry

  has_many :entry_scribes, foreign_key: "scribe_id"
  has_many :scribe_entries, -> {distinct},  through: :entry_scribes, source: :entry

  has_many :sale_agents, foreign_key: "agent_id"
  has_many :sales, through: :sale_agents
  has_many :sale_entries, -> {distinct}, through: :sales, source: :entry

  has_many :provenance, foreign_key: "provenance_agent_id"
  has_many :provenance_entries, -> {distinct},  through: :provenance, source: :entry

  has_many :source_agents, foreign_key: "agent_id"
  has_many :sources, through: :source_agents
  has_many :agent_sources, -> {distinct},  through: :source_agents, source: :source

  has_many :comments, as: :commentable

  has_many :dericci_links
  has_many :dericci_records, through: :dericci_links

  #has_many :dericci_records, foreign_key: "verified_id"

  validates_presence_of :name

  accepts_nested_attributes_for :name_places, allow_destroy: true

  validate do |name_obj|
    if !(name_obj.is_artist || name_obj.is_author || name_obj.is_scribe || name_obj.is_provenance_agent)
      errors[:base] << "Name objects must have at least one flag set"
    end

    if name_obj.name.present? && (!name_obj.persisted? || name_obj.name_changed?)
      if self.class.unscoped.exists?(name: name_obj.name, deleted: true)
        errors[:name] << " is already used by a record that has been deleted"
      elsif (existing_name = self.class.find_by(name: name_obj.name)).present? && name_obj.id != existing_name.id
        errors[:name] << " is already used by record <a href='/names/#{existing_name.id}' target='_blank'>#{existing_name.name}</a>"
      end
    end

    if name_obj.viaf_id.present? && (!name_obj.persisted? || name_obj.viaf_id_changed?)
      if self.class.unscoped.exists?(viaf_id: name_obj.viaf_id, deleted: true)
        errors[:viaf_id] << " is already used by a record that has been deleted"
      elsif (existing_name = self.class.find_by(viaf_id: name_obj.viaf_id)).present? && name_obj.id != existing_name.id
        errors[:viaf_id] << " is already used by record <a href='/names/#{existing_name.id}' target='_blank'>#{existing_name.name}</a>".html_safe
      else
        name_obj.viaf_id = name_obj.viaf_id.strip unless name_obj.viaf_id.nil?
      end
    end
  end

  before_validation :normalize

  def normalize
    self.name = self.name.mb_chars.normalize
  end

  searchable :unless => :deleted do
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
    text :other_info, :as => :other_info_text_pre
    string :other_info
    integer :id
    text :name, :more_like_this => true do
      silence_warnings {
        [name.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').downcase.to_s, name]
      }
    end
    string :name do
      silence_warnings {
        name.mb_chars.normalize(:kd).gsub(/[^\x00-\x7F]/n,'').downcase.to_s
      }
    end
    string :viaf_id
    string :subtype
    string :places do
      places.map(&:name).join("; ")
    end
    text :places do
      places.map(&:name).join("; ")
    end
    integer :created_by_id
    integer :artists_count
    integer :authors_count # test
    integer :scribes_count
    integer :source_agents_count
    integer :sale_agents_count
    integer :provenance_count

    string :startdate do
      startdate.present? ? startdate.split("-").in_groups_of(3).first.map{ |d| d.to_s.rjust(2, "01") }.join("").rjust(8, "0") : nil
    end
    string :enddate do
      enddate.present? ? enddate.split("-").in_groups_of(3).first.map{ |d| d.to_s.rjust(2, "01") }.join("").rjust(8, "0") : nil
    end

    date :created_at
    date :updated_at
    boolean :reviewed
    boolean :problem

    integer :confirms do
      ratings.where(qualifier: "confirm").count
    end

    integer :disputes do
      ratings.where(qualifier: "dispute").count
    end
  end

  def self.filters
    super + [
      ["VIAF", "viaf_id"],
      ["Author Count", "authors_count"],
      ["Artist Count", "artists_count"],
      ["Scribe Count", "scribes_count"],
      ["Provenance Count", "provenance_count"],
      ["Source Agent Count", "source_agents_count"],
      ["# of Confirms", "confirms"],
      ["# of Disputes", "disputes"],
      ["Problem", "problem"],
      ["Type", "subtype"]
    ]
  end

  def self.fields
    super + [["Other Info", "other_info"], ["Places", "places"]]
  end

  def self.dates
    super + [["Start Date", "startdate"], ["End Date", "enddate"]]
  end

  def search_result_format
    {
      id: id,
      name: name,
      viaf_id: viaf_id,
      other_info: other_info,
      subtype: subtype,
      places: places.map(&:name).join("; "),
      startdate: startdate,
      enddate: enddate,
      authors_count: authors_count,
      artists_count: artists_count,
      scribes_count: scribes_count,
      source_agents_count: source_agents_count,
      sale_agents_count: sale_agents_count,
      provenance_count: provenance_count,
      is_artist: is_artist,
      is_author: is_author,
      is_provenance_agent: is_provenance_agent,
      is_scribe: is_scribe,
      reviewed: reviewed,
      problem: problem,
      confirms: ratings.where(qualifier: "confirm").count,
      disputes: ratings.where(qualifier: "dispute").count,
      created_by: created_by.present? ? created_by.username : "(none)",
      created_at: created_at.present? ? created_at.to_formatted_s(:long) : "",
      updated_by: updated_by.present? ? updated_by.username : "(none)",
      updated_at: updated_at.present? ? updated_at.to_formatted_s(:long) : ""
    }
  end

  ###
  #
  # This is all used only for creating reference data
  #
  ###

  # constructor for a Provenance Agent. takes same args as #new
  def self.agent(*args)
    hash = args.last.is_a?(Hash) ? args.pop : {}
    new(*(args << hash.merge(is_provenance_agent: true)))
  end

  # constructor for an Artist. takes same args as #new
  def self.artist(*args)
    hash = args.last.is_a?(Hash) ? args.pop : {}
    new(*(args << hash.merge(is_artist: true)))
  end

  # constructor for an Author. takes same args as #new
  def self.author(*args)
    hash = args.last.is_a?(Hash) ? args.pop : {}
    new(*(args << hash.merge(is_author: true)))
  end

  # constructor for a Scribe. takes same args as #new
  def self.scribe(*args)
    hash = args.last.is_a?(Hash) ? args.pop : {}
    new(*(args << hash.merge(is_scribe: true)))
  end

  # This find_or_create constructor looks for a name, creating it if
  # necessary, while also flagging it as is_artist, is_author, etc
  # according to passed in 'flag' arg, which should be a symbol.
  def self.find_or_create_by_flag(name, flag)
    obj = where(name: name).first
    if obj
      if !obj.send(flag)
        obj.send("#{flag}=", true)
        obj.save!
      end
    else
      attrs = {
        name: name,
      }
      attrs[flag] = true
      obj = create!(attrs)
    end
    obj
  end

  def self.find_or_create_agent(name)
    find_or_create_by_flag(name, :is_provenance_agent)
  end

  def self.find_or_create_artist(name)
    find_or_create_by_flag(name, :is_artist)
  end

  def self.find_or_create_author(name)
    find_or_create_by_flag(name, :is_author)
  end

  def self.find_or_create_scribe(name)
    find_or_create_by_flag(name, :is_scribe)
  end

  def lookup_type
    xmldoc = Nokogiri::XML(response.body)
    number_of_records = xmldoc.xpath("//ns:numberOfRecords", "ns" => VIAF::NS::LC).first
    if number_of_records
      xmldoc.xpath("//ns:record/ns:recordData", "ns" => VIAF::NS::LC).each do |record_data|
        cluster = record_data.xpath("ns:VIAFCluster", "ns" => VIAF::NS::VIAF).first
        name_type = cluster.xpath("ns:nameType", "ns" => VIAF::NS::VIAF).first
        self.update(subtype: name_type.text)
      end
    end
  end

  # Finds suggestions for the passed-in name string, based on results
  # from searching VIAF. return value is a Hash with keys
  # "already_exists" and "results".
  def self.suggestions(name, check_if_name_already_exists: true, debug: false)
    error = nil
    results = []

    # check that name doesn't already exist
    name_exists = false
    if check_if_name_already_exists
      name_exists = exists?(name: name)
    end

    if !check_if_name_already_exists || !name_exists
      # we don't use VIAF's autosuggest because what it returns isn't
      # really useful here. so we use sru_search instead.

      # include both People (personalNames) and Organizations (corporateNames)
      cql = "(local.personalNames all \"#{name}\" or local.corporateNames all \"#{name}\")"

      response = VIAF.sru_search(cql)

      if debug
        File.open("/tmp/names/#{response.code} - #{name.gsub('/', '')}", "wb") do |f|
          f.write(response.body)
        end
      end

      if response.code == '200'
        xmldoc = Nokogiri::XML(response.body)

        number_of_records = xmldoc.xpath("//ns:numberOfRecords", "ns" => VIAF::NS::LC).first
        if number_of_records
          xmldoc.xpath("//ns:record/ns:recordData", "ns" => VIAF::NS::LC).each do |record_data|
            cluster = record_data.xpath("ns:VIAFCluster", "ns" => VIAF::NS::VIAF).first

            # name_type in Name record to designate person ("Personal") or institution ("Corporate")
            name_type = cluster.xpath("ns:nameType", "ns" => VIAF::NS::VIAF).first
            viaf_id = cluster.xpath("ns:viafID", "ns" => VIAF::NS::VIAF).first

            birth_date = cluster.xpath("ns:birthDate", "ns" => VIAF::NS::VIAF).first
            death_date = cluster.xpath("ns:deathDate", "ns" => VIAF::NS::VIAF).first

            found_lc_name = false

            if name_type.text == "Personal" || name_type.text == "Corporate"
              # each 'data' element contains a name and the sources that use them,
              # so look through them
              cluster.xpath("ns:mainHeadings/ns:data", "ns" => VIAF::NS::VIAF).each do |data|
                break if found_lc_name
                has_lc = data.xpath("ns:sources", "ns" => VIAF::NS::VIAF).children.select { |s| s.text == "LC" }.length > 0
                if has_lc
                  name = data.xpath("ns:text", "ns" => VIAF::NS::VIAF).first.text
                  found_lc_name = true
                  results << {
                    name: name,
                    viaf_id: viaf_id.text,
                    subtype: name_type.text,
                    birth_date: birth_date.text,
                    death_date: death_date.text
                  }
                end
              end
              # if there is NO library of congress name, use the first available name
              if not found_lc_name
                data = cluster.xpath("ns:mainHeadings/ns:data", "ns" => VIAF::NS::VIAF).first
                  name = data.xpath("ns:text", "ns" => VIAF::NS::VIAF).first.text
                  results << {
                    name: name,
                    viaf_id: viaf_id.text,
                    subtype: name_type.text,
                    birth_date: birth_date.text,
                    death_date: death_date.text
                  }
              end
            else
              puts "Don't known how to deal with nameType=#{name_type.text}"
            end
          end
        else
          Rails.logger.warn "numberOfRecords element not found in VIAF XML"
        end
      else
        error = "HTTP response error code: #{response.code}"
      end
    end

    {
      already_exists: name_exists,
      results: results,
      error: error,
    }
  end

  def dispute_reasons
    ["Wrong VIAF number", "Name refers to more than one individual", "Does not follow formatting standards", "Name contains incorrect information", "Other"]
  end

  def public_id
    #is_provenance_agent ?  "SDBM_AGENT_#{id}" : SDBMSS::IDS.get_public_id_for_model(self.class, id)
    SDBMSS::IDS.get_public_id_for_model(self.class, id)
  end

  def to_s
    name
  end

  def to_i
    id
  end

  def as_flat_hash
    {id: id, name: name, viaf_id: viaf_id, subtype: subtype, created_at: created_at, created_by: created_by, other_info: other_info }
  end

  def bookmark_details
    results = {
      name: name,
      viaf_id: viaf_id,
      used_as_author: authors_count > 0 ? "#{authors_count} entries" : nil,
      used_as_scribe: scribes_count > 0 ? "#{scribes_count} entries" : nil,
      used_as_artist: artists_count > 0 ? "#{artists_count} entries" : nil,
      used_as_source_agent: source_agents_count > 0 ? "#{source_agents_count} sources" : nil,
      used_as_sale_agent: sale_agents_count > 0 ? "#{sale_agents_count} sources" : nil,
      used_as_provenance: provenance_count > 0 ? "#{provenance_count} entries" : nil
    }
    (results.select { |k, v| !v.blank? }).transform_keys{ |key| key.to_s.humanize }
  end

  def entry_ids_to_index_on_update
    ids = Set.new
    ids.merge(Entry.joins(:artists).where({ names: { id: id }}).select(:id).map(&:id))
    ids.merge(Entry.joins(:authors).where({ names: { id: id }}).select(:id).map(&:id))
    ids.merge(Entry.joins(:scribes).where({ names: { id: id }}).select(:id).map(&:id))
    ids.merge(Entry.joins(:sales => :sale_agents).where({ sale_agents: { agent_id: id }}).select(:id).map(&:id))
    ids.merge(Entry.joins(:provenance).where({ provenance: { provenance_agent_id: id }}).select(:id).map(&:id))
    ids.merge(Entry.joins(:source => :source_agents).where({ source_agents: { agent_id: id }}).select(:id).map(&:id))
    ids.to_a
  end

  def entries_to_index_on_update
    # because Name is used in many places, we build an array of IDs
    # and construct a single Relation which callers can whittle down
    # into batches.
    SDBMSS::ModelBatch.new(Entry, entry_ids_to_index_on_update)
  end

  # merges this record into target, soft-deleting this record.
  def merge_into(target)
    target_id = target.id
    # Find all the Entries attached to this name, that will need to be
    # reindexed after the merge
    entry_ids = entry_ids_to_index_on_update

    ids = EntryArtist.where(artist_id: self.id).pluck(:id)
    EntryArtist.where(artist_id: self.id).update_all({ artist_id: target_id })
    EntryArtist.where( id: ids ).each(&:update_bunny)

    ids = EntryAuthor.where(author_id: self.id).pluck(:id)
    EntryAuthor.where(author_id: self.id).update_all({ author_id: target_id })
    EntryAuthor.where( id: ids ).each(&:update_bunny)

    ids = EntryScribe.where(scribe_id: self.id).pluck(:id)
    EntryScribe.where(scribe_id: self.id).update_all({ scribe_id: target_id })
    EntryScribe.where( id: ids ).each(&:update_bunny)

    ids = SaleAgent.where(agent_id: self.id).pluck(:id)
    SaleAgent.where(agent_id: self.id).update_all({ agent_id: target_id })
    SaleAgent.where( id: ids ).each(&:update_bunny)

    ids = SourceAgent.where(agent_id: self.id).pluck(:id)
    SourceAgent.where(agent_id: self.id).update_all({ agent_id: target_id })
    SourceAgent.where( id: ids ).each(&:update_bunny)

    ids = Provenance.where(provenance_agent_id: self.id).pluck(:id)
    Provenance.where(provenance_agent_id: self.id).update_all({ provenance_agent_id: target_id })
    Provenance.where( id: ids ).each(&:update_bunny)

    ids = DericciLink.where(name_id: self.id).pluck(:id)
    DericciLink.where(name_id: self.id).update_all({ name_id: target_id })
    DericciLink.where( id: ids ).each(&:update_bunny)

    ids = DericciRecord.where(verified_id: self.id).pluck(:id)
    DericciRecord.where(verified_id: self.id).update_all({verified_id: target_id})
    DericciRecord.where( id: ids ).each(&:update_bunny)

    # update flags on the target
    target.is_artist ||= self.is_artist
    target.is_author ||= self.is_author
    target.is_scribe ||= self.is_scribe
    target.is_provenance_agent ||= self.is_provenance_agent

    target.save

    # but ... CAN't SAVE when name is BLANK (nil)
    # self.name = nil
    self.viaf_id = nil
    self.deleted = true
    self.save!

    # slice into managable chunks to avoid running out of space in mysql
    entry_ids.each_slice(200) do |slice|
      SDBMSS::IndexJob.perform_later(Entry.to_s, slice)
    end

    Name.update_counters(target.id,
      :authors_count => target.author_entries.where(deprecated: false, draft: false).count - target.authors_count,
      :artists_count => target.artist_entries.where(deprecated: false, draft: false).count - target.artists_count,
      :scribes_count => target.scribe_entries.where(deprecated: false, draft: false).count - target.scribes_count,
      :sale_agents_count => target.sale_entries.where(deprecated: false, draft: false).count - target.sale_agents_count,
      :provenance_count => target.provenance_entries.where(deprecated: false, draft: false).count - target.provenance_count,
      :source_agents_count => target.agent_sources.count - target.source_agents_count
    )
  end

  def update_count()
    Name.reset_counters(self.id, :entry_authors, :entry_artists, :entry_scribes, :sale_agents, :source_agents, :provenance)
  end

  def to_rdf
    map = {
      model_class: "names",
      id: id,
      fields: {}
    }

    map[:fields][:name]       = format_triple_object name,       :string
    map[:fields][:viaf_id]    = format_triple_object viaf_id,    :string
    map[:fields][:subtype]    = format_triple_object subtype,    :string
    map[:fields][:startdate]  = format_triple_object startdate,  :string
    map[:fields][:enddate]    = format_triple_object enddate,    :string
    map[:fields][:other_info] = format_triple_object other_info, :string
    map[:fields][:deleted]    = format_triple_object deleted,    :boolean

    map
  end

end