
module HasPaperTrail

  extend ActiveSupport::Concern

  included do
    has_paper_trail skip: [:updated_at, :authors_count, :provenance_count, :artists_count, :scribes_count, :source_agents_count, :sale_agents_count, :entries_count, :order ]
  end

end
