class SourceAgent < ActiveRecord::Base
  belongs_to :source
  belongs_to :agent, class_name: 'Name', counter_cache: :source_agents_count

  validate :validate_role

  ROLE_SELLER_OR_HOLDER = "seller_or_holder"
  ROLE_SELLING_AGENT = "selling_agent"
  ROLE_BUYER = "buyer"
  ROLE_INSTITUTION = "institution"
  ROLE_DONOR = "donor"
  ROLE_RECIPIENT = "recipient"

  ROLE_TYPES = [
    [ROLE_SELLER_OR_HOLDER, "Seller or Holder"],
    [ROLE_SELLING_AGENT, "selling agent"],
    [ROLE_BUYER, "Buyer"],
    [ROLE_INSTITUTION, "Institution"],
    [ROLE_DONOR, "Donor"],
    [ROLE_RECIPIENT, "Recipient"],
  ]

  validates_presence_of :agent
  validates_presence_of :source

  def self.valid_roles_for_source_type(source_type_code)
    case source_type_code
    when SourceType::AUCTION_CATALOG
      valid_roles = [ROLE_SELLING_AGENT]
    when SourceType::COLLECTION_CATALOG
      valid_roles = [ROLE_INSTITUTION]
    when SourceType::ONLINE
      valid_roles = [ROLE_SELLING_AGENT]
    when SourceType::OBSERVATION
      valid_roles = []
    when SourceType::OTHER_PUBLISHED
      valid_roles = []
    when SourceType::UNPUBLISHED
      valid_roles = [ROLE_INSTITUTION]
    end
    valid_roles
  end

  def valid_roles_for_source_type
    self.class.valid_roles_for_source_type(source.source_type.name)
  end

  private

  def validate_role
    if !valid_roles_for_source_type.include?(role)
      errors.add(:role, "'#{role}' role not allowed in SourceAgent records for sources whose source_type = #{source.source_type.name}")
    end
  end

end
