module Ratable

  extend ActiveSupport::Concern

  included do
    has_many :ratings, as: :ratable
  end

  def dispute_reasons
    [["No Reason", "No Reason"], ["Other", "Other"]]
  end

end