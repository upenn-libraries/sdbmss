
class SourceType < ActiveRecord::Base

  # Constants whose string values we use for the 'name' field.
  #
  # Auction Catalog
  #   ex: Sotheby's
  # Collection Catalog
  #   ex: Penn's published catalog
  # Online-only Auction or Bookseller Website
  #   ex: Ebay, private bookseller websites
  # Personal Observation
  #   ex: An individual's set of personal (direct) observations
  # Other Published Source
  #   ex: DeRicci, censuses, journal articles
  # Unpublished
  #   ex: spreadsheet of Duke Univ. collection, Benjy's spreadsheet, and pretty much everything else.

  include TellBunny
  
  default_scope { order("id = 4 desc") }

  AUCTION_CATALOG = 'auction_catalog'
  COLLECTION_CATALOG = 'collection_catalog'
  ONLINE = 'online'
  OBSERVATION = 'observation'
  OTHER_PUBLISHED = 'other_published'
  UNPUBLISHED = 'unpublished'
  PROVENANCE_OBSERVATION = 'provenance_observation'

  def self.auction_catalog
    find_by(name: AUCTION_CATALOG)
  end

  def self.collection_catalog
    find_by(name: COLLECTION_CATALOG)
  end

  def self.online
    find_by(name: ONLINE)
  end

  def self.observation
    find_by(name: OBSERVATION)
  end

  def self.other_published
    find_by(name: OTHER_PUBLISHED)
  end

  def self.unpublished
    find_by(name: UNPUBLISHED)
  end

  def to_s
    display_name
  end

  # SourceType records should rarely, if ever, change
  def to_rdf
    {
      model_class: "source_types",
      id: id,
      fields: {
        name: "'''#{name}'''",
        display_name: "'''#{display_name}'''",
        entries_transaction_field: "'#{entries_transaction_field}'^^xsd:boolean",
        entries_have_institution_field: "'#{entries_have_institution_field}'^^xsd:boolean"
      }
    }
=begin
    %Q(
      sdbm:source_types/#{id}
      a       sdbm:source_types
      sdbm:source_types_id #{id}
      sdbm:source_types_name '#{name}'
      sdbm:source_types_display_name '#{display_name}'
      sdbm:source_types_entries_transaction_field '#{entries_transaction_field}'^^xsd:boolean
      sdbm:source_types_entries_have_institution_field '#{entries_have_institution_field}'^^xsd:boolean
    )
=end
  end

end