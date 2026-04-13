# frozen_string_literal: true

module Blacklight
  module SearchHelper
    def fetch_one(id, extra_controller_params)
      old_solr_doc_params = Deprecation.silence(Blacklight::SearchHelper) do
        solr_doc_params(id)
      end

      if default_solr_doc_params(id) != old_solr_doc_params
        Deprecation.warn Blacklight::SearchHelper, "The #solr_doc_params method is deprecated. Instead, you should provide a custom SolrRepository implementation for the additional behavior you're offering. The current behavior will be removed in Blacklight 6.0"
        extra_controller_params = extra_controller_params.merge(old_solr_doc_params)
      end

      # here!
      id = "Entry #{id}"

      solr_response = repository.find id, extra_controller_params
      [solr_response, solr_response.documents.first]
    end
  end
end
