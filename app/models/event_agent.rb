class EventAgent < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  belongs_to :event
  belongs_to :agent, class_name: 'Name', counter_cache: :event_agents_count

  validates_presence_of :event

  validate do |event_agent|
    if !(event_agent.agent.present? || event_agent.observed_name.present?)
      errors[:base] << "EventAgent objects must have either Agent association or observed_name value"
    end
  end

  ROLE_SELLER_OR_HOLDER = "seller_or_holder"
  ROLE_SELLING_AGENT = "selling_agent"
  ROLE_BUYER = "buyer"

  ROLE_TYPES = [
    [ROLE_SELLER_OR_HOLDER, "Seller or Holder"],
    [ROLE_SELLING_AGENT, "Selling Agent"],
    [ROLE_BUYER, "Buyer"],
  ]

  # returns true if this EventAgent record should be (conceptually)
  # considered part of the Entry's provenance. This is used for
  # faceting/search on "Provenance" field.
  def is_provenance
    # don't include selling agents
    [ROLE_SELLER_OR_HOLDER, ROLE_BUYER].member? role
  end

end
