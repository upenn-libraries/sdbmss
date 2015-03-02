
class Source < ActiveRecord::Base

  TYPE_BLANK = nil

  TYPE_AUCTION_CATALOG = 'auction_catalog'
  TYPE_COLLECTION_CATALOG = 'collection_catalog'
  TYPE_OTHER_PUBLISHED = 'other_published'
  TYPE_UNPUBLISHED = 'unpublished'

  SOURCE_TYPES = [
    # Auction Catalogs include Sotheby's
    [TYPE_AUCTION_CATALOG, 'Auction/Sale Catalog'],
    # Collection Catalogs include things like Penn's published catalog
    [TYPE_COLLECTION_CATALOG, 'Collection Catalog'],
    # Other Published Source includes DeRicci, censuses, journal articles
    [TYPE_OTHER_PUBLISHED, 'Other Published Source'],
    # TODO: ???
    [TYPE_UNPUBLISHED, 'Unpublished'],
  ]

  TYPE_HAS_MANUSCRIPT_YES = 'Yes'
  TYPE_HAS_MANUSCRIPT_NO = 'No'
  TYPE_HAS_MANUSCRIPT_MAYBE = 'Maybe'

  HAS_MANUSCRIPT_TYPES = [
    [TYPE_BLANK, ''],
    [TYPE_HAS_MANUSCRIPT_YES, TYPE_HAS_MANUSCRIPT_YES],
    [TYPE_HAS_MANUSCRIPT_NO, TYPE_HAS_MANUSCRIPT_NO],
    [TYPE_HAS_MANUSCRIPT_MAYBE, TYPE_HAS_MANUSCRIPT_MAYBE],
  ]

  TYPE_STATUS_TO_BE_ENTERED = 'To Be Entered'
  TYPE_STATUS_PARTIALLY_ENTERED = 'Partially Entered'
  TYPE_STATUS_ENTERED = 'Entered'
  TYPE_STATUS_NO_MSS = 'No MSS'

  # status can be either "No MSS" or "To Be Entered" => "Partially Entered" => "Entered"
  STATUS_TYPES = [
    [TYPE_STATUS_TO_BE_ENTERED, TYPE_STATUS_TO_BE_ENTERED],
    [TYPE_STATUS_PARTIALLY_ENTERED, TYPE_STATUS_PARTIALLY_ENTERED],
    [TYPE_STATUS_ENTERED, TYPE_STATUS_ENTERED],
    [TYPE_STATUS_NO_MSS, TYPE_STATUS_NO_MSS],
  ]

  TYPE_PUBLICLY_AVAILABLE_YES = 'Yes'
  TYPE_PUBLICLY_AVAILABLE_NO = 'No'
  TYPE_PUBLICLY_AVAILABLE_MAYBE = 'Maybe'

  PUBLICLY_AVAILABLE_TYPES = [
    [TYPE_BLANK, ''],
    [TYPE_PUBLICLY_AVAILABLE_YES, TYPE_PUBLICLY_AVAILABLE_YES],
    [TYPE_PUBLICLY_AVAILABLE_NO, TYPE_PUBLICLY_AVAILABLE_NO],
    [TYPE_PUBLICLY_AVAILABLE_MAYBE, TYPE_PUBLICLY_AVAILABLE_MAYBE],
  ]

  include UserFields

  before_validation :normalize

  has_many :entries
  has_many :source_agents, inverse_of: :source

  validates_inclusion_of :source_type, in: SOURCE_TYPES.map(&:first), message: 'source type is invalid'
  validates_inclusion_of :whether_mss, in: HAS_MANUSCRIPT_TYPES.map(&:first), message: 'whether_mss is invalid'
  validates_inclusion_of :electronic_publicly_available, in: PUBLICLY_AVAILABLE_TYPES.map(&:first), message: 'electronic_publicly_available is invalid'
  validates_presence_of :date, if: :date_required

  accepts_nested_attributes_for :source_agents

  # returns 'count' number of most recent sources
  scope :most_recent, ->(count = 5) { order(created_at: :desc).first(count) }

  def public_id
    "SDBM_SOURCE_#{id}"
  end

  def normalize
    if self.date
      self.date.gsub!("-", "")
    end
  end

  # date field is only required for certain types of sources
  def date_required
    [TYPE_UNPUBLISHED].member? source_type
  end

  def get_source_agent_with_role(role)
    source_agents.select { |sa| sa.role == role }.first
  end

  def get_seller_or_holder
    get_source_agent_with_role(SourceAgent::ROLE_SELLER_OR_HOLDER)
  end

  def get_selling_agent
    get_source_agent_with_role(SourceAgent::ROLE_SELLING_AGENT)
  end

  def get_institution
    get_source_agent_with_role(SourceAgent::ROLE_INSTITUTION)
  end

  def get_source_type_for_display
    record = SOURCE_TYPES.select { |record| record[0] == source_type }.first
    record ? record[1] : "Unknown"
  end

  # returns true if entries should have a transaction record
  # associated with them
  def entries_have_a_transaction
    !(source_type == TYPE_COLLECTION_CATALOG || source_type == TYPE_OTHER_PUBLISHED)
  end

  # returns true if entries should use institution/collection field
  def entries_have_institution
    source_type == TYPE_OTHER_PUBLISHED
  end

  def to_s
    display_value
  end

  # Returns 3-part display string for Source
  def display_value
    date_str = ""
    if date
      date_str = SDBMSS::Util.format_fuzzy_date(date)
    end

    agent_str = ""
    if source_type == TYPE_AUCTION_CATALOG
      selling_agent = get_selling_agent
      agent_str = selling_agent.agent.name if selling_agent && selling_agent.agent
    elsif source_type == TYPE_COLLECTION_CATALOG
      institution = get_institution
      agent_str = institution.agent.name if institution && institution.agent
    else
      # institution takes precedence for display
      source_agent = get_institution || get_selling_agent
      agent_str = source_agent.agent.name if source_agent && source_agent.agent
    end

    title_str = title || "(No title)"

    pieces = [date_str, agent_str, title_str].select { |x| x.to_s.length > 0 }.join(" - ")
  end

end
