
module IndexAfterUpdate

  extend ActiveSupport::Concern

  included do
    after_update :index_after_update
  end

  def index_after_update
    if SDBMSS::IndexJob.has_entries_to_index_on_update?(self.class)
      SDBMSS::IndexJob.perform_later(self.class.to_s, [ id ])
    else
      raise "model class #{self.class.to_s} doesn't have #entries_to_index_on_update method"
    end
  end

end
