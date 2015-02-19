class EventAgent < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :event
  belongs_to :agent

  validates_presence_of :event

  ROLE_SELLER_OR_HOLDER = "seller_or_holder"
  ROLE_SELLER_AGENT = "seller_agent"
  ROLE_BUYER = "buyer"

  ROLE_TYPES = [
    [ROLE_SELLER_OR_HOLDER, "Seller or Holder"],
    [ROLE_SELLER_AGENT, "Seller Agent"],
    [ROLE_BUYER, "Buyer"],
  ]

  # returns true if this EventAgent record should be (conceptually)
  # considered part of the Entry's provenance. This is used for
  # faceting/search on "Provenance" field.
  def is_provenance
    # don't include seller agents
    [ROLE_SELLER_OR_HOLDER, ROLE_BUYER].member? role
  end

end
