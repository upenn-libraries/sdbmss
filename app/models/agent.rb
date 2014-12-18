class Agent < ActiveRecord::Base
  belongs_to :entry
  belongs_to :approved_by, :class_name => 'User'

  has_many :event_agents
  has_many :events, through: :event_agents

  has_many :source_agents
  has_many :sources, through: :source_agents

  def get_public_id
    "SDBM_AGENT_#{id}"
  end

end
