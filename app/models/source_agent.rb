class SourceAgent < ActiveRecord::Base
  belongs_to :source
  belongs_to :agent, class_name: 'Name', counter_cache: :source_agents_count

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

end
