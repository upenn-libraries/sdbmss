class SourceAgent < ActiveRecord::Base
  belongs_to :source
  belongs_to :agent

  ROLE_SELLER_OR_HOLDER = "seller_or_holder"
  ROLE_SELLER_AGENT = "seller_agent"
  ROLE_BUYER = "buyer"
  ROLE_INSTITUTION = "institution"
  ROLE_DONOR = "donor"
  ROLE_RECIPIENT = "recipient"

  ROLE_TYPES = [
    [ROLE_SELLER_OR_HOLDER, "Seller or Holder"],
    [ROLE_SELLER_AGENT, "Seller Agent"],
    [ROLE_BUYER, "Buyer"],
    [ROLE_INSTITUTION, "Institution"],
    [ROLE_DONOR, "Donor"],
    [ROLE_RECIPIENT, "Recipient"],
  ]

  validates_presence_of :source

end
