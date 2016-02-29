
module HasPaperTrail

  extend ActiveSupport::Concern

  included do
    has_paper_trail skip: [:created_at, :updated_at, :touch_count, :order]
  end

end
