
require 'sdbmss/util'

class Source < ActiveRecord::Base
  belongs_to :added_by, :class_name => 'User'
  belongs_to :last_modified_by, :class_name => 'User'

  has_many :entries
  has_many :source_agents

  # returns 'count' number of most recent sources
  scope :most_recent, ->(count = 5) { order(added_on: :desc).first(count) }

  TYPE_AUCTION_CATALOG = 'auction_catalog'
  TYPE_COLLECTION_CATALOG = 'collection_catalog'
  TYPE_OTHER_PUBLISHED = 'other_published'
  TYPE_UNPUBLISHED = 'unpublished'

  SOURCE_TYPES = [
    [TYPE_AUCTION_CATALOG, 'Auction/Sale Catalog'],
    [TYPE_COLLECTION_CATALOG, 'Collection Catalog'],
    [TYPE_OTHER_PUBLISHED, 'Other Published Source'],
    [TYPE_UNPUBLISHED, 'Unpublished'],
  ]

  def get_source_agent_with_role(role)
    source_agents.select { |sa| sa.role == role }.first
  end

  def get_seller_or_holder
    get_source_agent_with_role(SourceAgent::ROLE_SELLER_OR_HOLDER)
  end

  def get_seller_agent
    get_source_agent_with_role(SourceAgent::ROLE_SELLER_AGENT)
  end

  def get_institution
    get_source_agent_with_role(SourceAgent::ROLE_INSTITUTION)
  end

  def get_source_type_for_display
    record = SOURCE_TYPES.select { |record| record[0] == source_type }.first
    record ? record[1] : "Unknown"
  end

  # Returns 3-part display string for Source
  def get_display_value
    date_str = ""
    if date
      date_str = SDBMSS::Util.format_fuzzy_date(date)
    end

    agent_str = ""
    if source_type == TYPE_AUCTION_CATALOG
      seller_agent = get_seller_agent
      agent_str = seller_agent.agent.name if seller_agent
    elsif source_type == TYPE_COLLECTION_CATALOG
      institution = get_institution
      agent_str = institution.agent.name if institution
    else
      # institution takes precedence for display
      source_agent = get_institution || get_seller_agent
      agent_str = source_agent.agent.name if source_agent
    end

    title_str = title || "(No title)"

    pieces = [date_str, agent_str, title_str].select { |x| x.to_s.length > 0 }.join(" - ")
  end

end
