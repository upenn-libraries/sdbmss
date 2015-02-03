class EventAgent < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :event
  belongs_to :agent

  ROLE_SELLER_OR_HOLDER = "seller_or_holder"
  ROLE_SELLER_AGENT = "seller_agent"
  ROLE_BUYER = "buyer"

  ROLE_TYPES = [
    [ROLE_SELLER_OR_HOLDER, "Seller or Holder"],
    [ROLE_SELLER_AGENT, "Seller Agent"],
    [ROLE_BUYER, "Buyer"],
  ]

end
