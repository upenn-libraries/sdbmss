
# This is the place where all the names of people and institutions,
# associated with Entries in various ways, are stored.
class Name < ActiveRecord::Base

  default_scope { where(deleted: false) }

  belongs_to :entry

  belongs_to :approved_by, :class_name => 'User'

  include UserFields

  has_many :entry_artists, foreign_key: "artist_id"

  has_many :entry_authors, foreign_key: "author_id"

  has_many :entry_scribes, foreign_key: "scribes_id"

  has_many :event_agents, foreign_key: "agent_id"
  has_many :events, through: :event_agents

  has_many :source_agents, foreign_key: "agent_id"
  has_many :sources, through: :source_agents

  validates_presence_of :name

  validate do |name_obj|
    if !(name_obj.is_artist || name_obj.is_author || name_obj.is_scribe || name_obj.is_provenance_agent)
      errors[:base] << "Name objects must have at least one flag set"
    end
  end

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

  # Finds suggestions for the passed-in name string, based on results
  # from searching VIAF. return value is a Hash with keys
  # "already_exists" and "results".
  def self.suggestions(name)
    results = []

    # check that name doesn't already exist
    name_exists = exists?(name: name)

    if !name_exists
      # we don't use VIAF's autosuggest because what it returns isn't
      # really useful here. so we use sru_search instead.

      # include both People (personalNames) and Organizations (corporateNames)
      cql = "(local.personalNames all \"#{name}\" or local.corporateNames all \"#{name}\")"

      xmldoc = Nokogiri::XML(VIAF.sru_search(cql))

      number_of_records = xmldoc.xpath("//ns:numberOfRecords", "ns" => VIAF::NS::LC).first
      if number_of_records
        xmldoc.xpath("//ns:record/ns:recordData", "ns" => VIAF::NS::LC).each do |record_data|
          cluster = record_data.xpath("ns:VIAFCluster", "ns" => VIAF::NS::VIAF).first

          name_type = cluster.xpath("ns:nameType", "ns" => VIAF::NS::VIAF).first
          viaf_id = cluster.xpath("ns:viafID", "ns" => VIAF::NS::VIAF).first

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
                }
              end
            end
          else
            puts "Don't known how to deal with nameType=#{name_type.text}"
          end
        end
      else
        Rails.logger.warn "numberOfRecords element not found in VIAF XML"
      end
    end

    {
      already_exists: name_exists,
      results: results,
    }
  end

  def public_id
    is_provenance_agent ?  "SDBM_AGENT_#{id}" : "SDBM_NAME_#{id}"
  end

  def to_s
    name
  end

end
