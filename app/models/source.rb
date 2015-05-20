
class Source < ActiveRecord::Base

  TYPE_BLANK = nil

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

  # These are not all media, but this is the weird list we came up
  # with on 3/9/2015 meeting
  TYPE_MEDIUM_INTERNET = "internet"
  TYPE_MEDIUM_LIBRARY = "library"
  TYPE_MEDIUM_PUBLIC_INSTITUTION = "public_institution"
  TYPE_MEDIUM_PRIVATE_COLLECTION = "private_collection"
  TYPE_MEDIUM_PERSONAL_COMMUNICATION = "personal_communication"
  TYPE_MEDIUM_OTHER = "other"

  MEDIUM_TYPES = [
    [TYPE_MEDIUM_INTERNET, "Internet"],
    [TYPE_MEDIUM_LIBRARY, "Library"],
    [TYPE_MEDIUM_PUBLIC_INSTITUTION, "Public Institution"],
    [TYPE_MEDIUM_PRIVATE_COLLECTION, "Private Collection"],
    [TYPE_MEDIUM_PERSONAL_COMMUNICATION, "Personal Communication"],
    [TYPE_MEDIUM_OTHER, "Other"],
  ]

  include UserFields
  include IndexAfterUpdate

  default_scope { where(deleted: false) }

  before_validation :normalize

  belongs_to :source_type

  has_many :entries
  has_many :source_agents, inverse_of: :source

  validates_inclusion_of :whether_mss, in: HAS_MANUSCRIPT_TYPES.map(&:first), message: 'whether_mss is invalid'
  validates_inclusion_of :medium, in: MEDIUM_TYPES.map(&:first), message: 'medium is invalid', allow_nil: true
  #validates_presence_of :date, if: :date_required
  validates_presence_of :source_type
  validate :source_type_not_changed
  # TODO: validate that irrelevant fields for the source_type are NOT populated

  accepts_nested_attributes_for :source_agents, allow_destroy: true

  # returns 'count' number of most recent sources
  scope :most_recent, ->(count = 5) { order(created_at: :desc, id: :desc).first(count) }

  # aggressively load all associations; useful for cases where you
  # want to display the 'complete' info
  scope :with_associations, -> {
    includes(:source_type, :source_agents => [:agent])
  }

  def public_id
    "SDBM_SOURCE_#{id}"
  end

  def normalize
    if date.present?
      date.gsub!("-", "")
      if date.length < 8
        pad = 8 - date.length
        self.date += "0" * pad
      end
    end
  end

  # date field is only required for certain types of sources
  # def date_required
  #   [TYPE_UNPUBLISHED].member? source_type
  # end

  def get_source_agent_with_role(role)
    source_agents.select { |sa| sa.role == role }.first
  end

  # returns a SourceAgent object
  def get_seller_or_holder
    get_source_agent_with_role(SourceAgent::ROLE_SELLER_OR_HOLDER)
  end

  # returns an Name object
  def get_seller_or_holder_as_name
    sa = get_seller_or_holder
    sa.agent if sa
  end

  # returns a SourceAgent object
  def get_selling_agent
    get_source_agent_with_role(SourceAgent::ROLE_SELLING_AGENT)
  end

  # returns an Name object
  def get_selling_agent_as_name
    sa = get_selling_agent
    sa.agent if sa
  end

  # returns a SourceAgent object
  def get_institution
    get_source_agent_with_role(SourceAgent::ROLE_INSTITUTION)
  end

  # returns an Name object
  def get_institution_as_name
    sa = get_institution
    sa.agent if sa
  end

  def medium_for_display
    record = MEDIUM_TYPES.select { |record| record[0] == medium }.first
    record ? record[1] : "Unknown"
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
    if source_type.name == SourceType::AUCTION_CATALOG
      selling_agent = get_selling_agent
      agent_str = selling_agent.agent.name if selling_agent && selling_agent.agent
    elsif source_type.name == SourceType::COLLECTION_CATALOG
      institution = get_institution
      agent_str = institution.agent.name if institution && institution.agent
    else
      # institution takes precedence for display
      source_agent = get_institution || get_selling_agent
      if source_agent && source_agent.agent
        agent_str = source_agent.agent.name
      else
        agent_str = author if author
      end
    end

    title_str = title || "(No title)"

    pieces = [date_str, agent_str, title_str].select { |x| x.to_s.length > 0 }.join(" - ")
  end

  def source_type_not_changed
    if source_type_id_changed? && self.persisted?
      errors.add(:source_type, "Change of source_type not allowed")
    end
  end

  def entries_to_index_on_update
    Entry.with_associations.where(source_id: id)
  end

end
