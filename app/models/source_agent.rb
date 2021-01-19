class SourceAgent < ActiveRecord::Base
  belongs_to :source
  belongs_to :agent, class_name: 'Name', counter_cache: :source_agents_count

  validate :validate_role
  validate :observed_or_authority  

  include HasPaperTrail
  include TellBunny

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
      valid_roles = [ROLE_INSTITUTION]
    when SourceType::OTHER_PUBLISHED
      valid_roles = [ROLE_INSTITUTION]
    when SourceType::UNPUBLISHED
      valid_roles = [ROLE_INSTITUTION]
    end
    valid_roles
  end

  def valid_roles_for_source_type
    self.class.valid_roles_for_source_type(source.source_type.name)
  end

  def facet_value
    agent ? agent.name : nil
  end  

  def to_rdf
    map = {
      model_class: "source_agents",
      id: id,
      fields: {}
    }

    map[:fields][:observed_name] = "'''#{rdf_string_prep observed_name}'''"                if observed_name.present?
    map[:fields][:agent_id]      = "<https://sdbm.library.upenn.edu/names/#{agent_id}>"    if agent_id.present?
    map[:fields][:role]          = "'''#{rdf_string_prep role}'''"                         if role.present?
    map[:fields][:source_id]     = "<https://sdbm.library.upenn.edu/sources/#{source_id}>" if source_id.present?

    map
  end

  private

  def validate_role
    if !valid_roles_for_source_type.include?(role)
      errors.add(:role, "'#{role}' role not allowed in SourceAgent records for sources whose source_type = #{source.source_type.name}")
    end
  end

  def observed_or_authority
    if observed_name.blank? && agent.blank?
      errors[:base] << "Either an observed value or authority name are required (or both)"
    end
  end

end
