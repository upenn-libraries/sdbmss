# frozen_string_literal: true

module SDBMSS
  class DocumentComponent < ::Blacklight::DocumentComponent
    delegate :current_search_session, :session_tracking_path,
             :render_document_class,
             :source_path, :name_path, :entry_path, :place_path,
             to: :helpers

    def entry
      @entry ||= @document.model_object
    end

    def entry_valid?
      entry.present? && entry.persisted?
    end
  end
end
