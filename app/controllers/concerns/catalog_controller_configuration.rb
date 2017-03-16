
# Configuration for controllers that use Blacklight.
#
# This should probably be renamed BlacklightControllerConfiguration
# for better clarity.
module CatalogControllerConfiguration

  extend ActiveSupport::Concern

  included do

    configure_blacklight do |config|
      
      config.max_per_page = Rails.configuration.sdbmss_max_search_results

      config.response_model = SDBMSS::Blacklight::SolrResponse

      config.document_presenter_class = SDBMSS::Blacklight::DocumentPresenter

      config.search_builder_class = SDBMSS::Blacklight::SearchBuilder

        ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
      config.default_solr_params = {
        # use dismax query parser
        :defType => 'edismax',
        # we load entry fields from db, so these are the only fields we need returned from solr
        :fl => 'id, entry_id',
        :rows => 10,
        'facet.mincount' => 1,
      }

      config.advanced_search = {
        :query_parser => "edismax"
      }

      ## Default parameters to send on single-document requests to Solr. These settings are the Blackligt defaults (see SolrHelper#solr_doc_params) or 
      ## parameters included in the Blacklight-jetty document requestHandler.
      config.default_document_solr_params = {
        # keep our solr config simple by avoiding a 'document' querytype
        # definition; instead we use the params below.
        # :qt => 'document',
        ## These are hard-coded in the blacklight 'document' requestHandler
        :rows => 1,
        :q => '{!raw f=id v=$id}' 
      }

      # solr field configuration for search results/index views
      config.index.title_field = ''
      config.index.display_type_field = 'format'

      # REMOVE: replaced by new csv method
=begin
      config.index.respond_to.csv = Proc.new {
        puts "is this still being used????"
        # this gets executed within a format.csv { ... } scope

        count = @response["response"]["numFound"]
        if count <= search_results_max
          objects = @document_list.map { |document| document.model_object.as_flat_hash }

          headers = objects.first.keys
          formatter = Proc.new do |object|
            headers.map { |key| object[key] }
          end
          render csv: objects,
                 filename: "#{search_model_class.to_s.downcase.pluralize}.csv",
                 headers: headers,
                 format: formatter
        else
          error_msg = "Result set has #{count} records, cannot return more than #{search_results_max}"
          render status: :request_entity_too_large, content_type: "text/html", body: error_msg
        end
      }
=end

      # NOTE: the wiki docs say about the :single option that "Only one
      # value can be selected at a time. When the value is selected, the
      # value of this field is ignored when calculating facet counts for
      # this field." This behavior of facet counts is weird and
      # confusing, so we leave it off.

      config.add_facet_field 'author', :label => 'Author', :collapse => false, :limit => 3
      config.add_facet_field 'title', :label => 'Title', :collapse => false, :limit => 3
      config.add_facet_field 'sale_seller', :label => 'Seller', :collapse => false, :limit => 3
      config.add_facet_field 'sale_selling_agent', :label => 'Selling Agent', :collapse => false, :limit => 3
      config.add_facet_field 'sale_buyer', :label => 'Buyer', :collapse => false, :limit => 3
      config.add_facet_field 'institution', :label => 'Institution', :collapse => false, :limit => 3
      config.add_facet_field 'source_display', :label => 'Source', :collapse => false, :limit => 3
      config.add_facet_field 'source_type', :label => 'Source Type', :collapse => false, :limit => 3
      config.add_facet_field 'provenance', :label => 'Provenance', :limit => 3
      config.add_facet_field 'manuscript_date_range', :label => 'Manuscript Date', :limit => 3
      config.add_facet_field 'manuscript_public_id', :label => 'Manuscript', :limit => 3
      config.add_facet_field 'place', :label => 'Place', :limit => 3
      config.add_facet_field 'language', :label => 'Language', :limit => 3
      config.add_facet_field 'use', :label => 'Liturgical Use', :limit => 3
      config.add_facet_field 'artist', :label => 'Artist', :limit => 3
      config.add_facet_field 'scribe', :label => 'Scribe', :limit => 3
      config.add_facet_field 'material', :label => 'Material', :limit => 3
      config.add_facet_field 'folios', :label => 'Folios', :limit => 3
      config.add_facet_field 'num_lines_range', :label => 'Lines', :limit => 3
      config.add_facet_field 'num_columns', :label => 'Columns', :limit => 3
      config.add_facet_field 'height_range', :label => 'Height', :limit => 3
      config.add_facet_field 'width_range', :label => 'Width', :limit => 3
      config.add_facet_field 'miniatures_fullpage_range', :label => 'Miniatures Full Page', :limit => 3
      config.add_facet_field 'miniatures_large_range', :label => 'Miniatures Large', :limit => 3
      config.add_facet_field 'miniatures_small_range', :label => 'Miniatures Small', :limit => 3
      config.add_facet_field 'miniatures_unspec_size_range', :label => 'Miniatures Unspec Size', :limit => 3
      config.add_facet_field 'initials_historiated_range', :label => 'Historiated Initials', :limit => 3
      config.add_facet_field 'initials_decorated_range', :label => 'Decorated Initials', :limit => 3

      # Have BL send all facet field names to Solr, which has been the default
      # previously. Simply remove these lines if you'd rather use Solr request
      # handler defaults, or have no facets.
      config.add_facet_fields_to_solr_request!

      # NOTE: we render search results and individual entry page
      # directly from database, so we have no need to use
      # config.add_index_field and config.add_show_field here.

      # "fielded" search configuration. Used by pulldown, advanced
      # search page, administrative search page, and maybe other
      # places.
      #
      # For supported keys in hash, see rdoc for
      # Blacklight::SearchFields
      #
      # Search fields will inherit the :qt solr request handler from
      # config[:default_solr_parameters], OR can specify a different one
      # with a :qt key/value. Below examples inherit, except for subject
      # that specifies the same :qt as default for our own internal
      # testing purposes.
      #
      # The :key is what will be used to identify this BL search field internally,
      # as well as in URLs -- so changing it after deployment may break bookmarked
      # urls.  A display label will be automatically calculated from the :key,
      # or can be specified manually to be different.

      config.add_search_field 'all_fields', :label => 'All Fields' do |field|
        field.solr_local_parameters = { :qf => 'complete_entry' }
      end

      config.add_search_field('title') do |field|
        field.solr_parameters = { :qf => 'title_search' }
      end

      config.add_search_field('author') do |field|
        field.solr_parameters = { :qf => 'author_search' }
      end

      config.add_search_field('source_display', label: "Source") do |field|
        field.solr_local_parameters = { :qf => 'source_search' }
      end

      config.add_search_field('groups', label: "User Groups") do |field|
        field.solr_local_parameters = { :qf => 'groups' }
      end

      config.add_search_field('source_date', label: "Source Date") do |field|
        field.solr_local_parameters = { :qf => 'source_date' }
      end

      config.add_search_field('source', label: "Source ID (Full)") do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'source' }
      end

      config.add_search_field('source_agent', label: "Source Agent") do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'source_agent' }
      end

      config.add_search_field('institution', label: "Institution") do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'institution_search' }
      end

      config.add_search_field('selling_agent') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'sale_selling_agent_search' }
      end

      config.add_search_field('seller') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'sale_seller_search' }
      end

      config.add_search_field('buyer') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'sale_buyer_search' }
      end

      config.add_search_field('catalog_or_lot_number', label: "Catalog or Lot Number") do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'catalog_or_lot_number_search' }
      end

      config.add_search_field('language') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'language_search' }
      end

      config.add_search_field('material') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'material_search' }
      end

      config.add_search_field('place') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'place_search' }
      end

      config.add_search_field('liturgical_use') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'use_search' }
      end

      config.add_search_field('artist') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'artist_search' }
      end

      config.add_search_field('scribe') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'scribe_search' }
      end

      config.add_search_field('binding') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'binding_search' }
      end

      config.add_search_field('provenance') do |field|
        field.solr_local_parameters = { :qf => 'provenance_search' }
      end

      config.add_search_field('comment') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'comment_search' }
      end

      # NOTE is_numeric_field is NOT part of Blacklight field
      # configuration; it's a hash key we created, to support field
      # display on the advanced search page.

      config.add_search_field('folios') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'folios' }
      end

      config.add_search_field('manuscript_date', label: "Manuscript Date") do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'manuscript_date' }
      end

      config.add_search_field('num_lines') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'num_lines' }
      end

      config.add_search_field('num_columns') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'num_columns' }
      end

      config.add_search_field('height') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'height' }
      end

      config.add_search_field('width') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'width' }
      end

      config.add_search_field('miniatures_fullpage') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'miniatures_fullpage' }
      end

#      config.add_search_field('missing_authority_names') do |field|
#        field.include_in_simple_select = false
#        field.is_numeric_field = true
#        field.solr_local_parameters = { :qf => 'missing_authority_names' }
#      end

      config.add_search_field('miniatures_large') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'miniatures_large' }
      end

      config.add_search_field('miniatures_small') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'miniatures_small' }
      end

      config.add_search_field('miniatures_unspec_size') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'miniatures_unspec_size' }
      end

      config.add_search_field('initials_historiated') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'initials_historiated' }
      end

      config.add_search_field('initials_decorated') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'initials_decorated' }
      end

      config.add_search_field('price') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'sale_price' }
      end

      config.add_search_field('provenance_date', label: "Provenance Date") do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'provenance_date' }
      end

      config.add_search_field 'entry_id', :label => 'Entry ID' do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = false
        field.solr_local_parameters = { :qf => 'entry_id' }
      end

      config.add_search_field 'entry', :label => 'Entry ID (Full)' do |field|
        field.include_in_simple_select = true
        field.is_numeric_field = false
        field.solr_local_parameters = { :qf => 'entry' }
      end

      config.add_search_field 'manuscript', :label => 'Manuscript ID (Full)' do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = false
        field.solr_local_parameters = { :qf => 'manuscript' }
      end

      config.add_search_field 'created_by' do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = false
        field.solr_local_parameters = { :qf => 'created_by' }
      end

      config.add_search_field 'updated_by' do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = false
        field.solr_local_parameters = { :qf => 'created_by' }
      end

      # don't show this anywhere; this is defined only so that table
      # view of Entries can filter on approved flag
      config.add_search_field 'approved' do |field|
        field.include_in_simple_select = false
        field.include_in_advanced_search = false
        field.is_numeric_field = false
        field.solr_local_parameters = { :qf => 'approved' }
      end

      config.add_search_field 'created_at' do |field|
        field.include_in_advanced_search = true
        field.is_numeric_field = false
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'created_at'}
      end

      config.add_search_field 'updated_at' do |field|
        field.include_in_advanced_search = true
        field.is_numeric_field = false
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'created_at'}
      end

      # "sort results by" select (pulldown)
      # label in pulldown is followed by the name of the SOLR field to sort by and
      # whether the sort is ascending or descending (it must be asc or desc
      # except in the relevancy case).

      config.add_sort_field 'entry_id asc', :label => 'ID (asc)'
      config.add_sort_field 'entry_id desc', :label => 'ID (desc)', default: true
      config.add_sort_field 'source_date asc', :label => 'Source Date (asc)'
      config.add_sort_field 'source_date desc', :label => 'Source Date (desc)'
      config.add_sort_field 'source_agent_sort asc', :label => 'Source Agent (asc)'
      config.add_sort_field 'source_agent_sort desc', :label => 'Source Agent (desc)'
#      config.add_sort_field 'title_flat asc', :label => 'Title'
#      config.add_sort_field 'title_flat desc', :label => 'Title (desc)'
#      config.add_sort_field 'manuscript_date_flat asc', :label => 'Manuscript Date'
#      config.add_sort_field 'manuscript_date_flat desc', :label => 'Manuscript Date (desc)'

      # config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
      # config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
      # config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
      # config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'

      # If there are more than this many search results, no spelling ("did you 
      # mean") suggestion is offered.
      config.spell_max = 5

      # this re-adds the search history, already included by the
      # default config, so we can specify the 'if' part

      config.navbar.partials.delete(:bookmark)
      config.navbar.partials.delete(:saved_searches)

      #config.add_nav_action(:bookmark, partial: 'blacklight/nav/bookmark', if: true)
      config.add_nav_action(:saved_searches, partial: 'blacklight/nav/saved_searches', if: true)
      config.add_nav_action(:search_history, partial: 'blacklight/nav/search_history', if: :render_search_history_control?)

      # fix me: despite needing an enourmous amount of configuration, blacklight doesn't let you easily customize something as simple as a dropdown menu

      config.add_results_collection_tool(:bookmark_all)
      config.add_results_collection_tool(:save_current_search)
#      config.add_results_collection_tool(:save_search)

      config.show.document_actions.delete(:email)
      config.show.document_actions.delete(:sms)
      config.show.document_actions.delete(:citation)

      #config.add_show_tools_partial(:edit_entry, partial: 'nav/edit_entry', if: :show_edit_entry_link?)
      config.add_show_tools_partial(:watch_entry, partial: 'nav/watch_entry')
      config.add_show_tools_partial(:linking_tool_by_entry, partial: 'nav/linking_tool_by_entry', if: :show_linking_tool_by_entry?)
      config.add_show_tools_partial(:linking_tool_by_manuscript, partial: 'nav/linking_tool_by_manuscript', if: :show_linking_tool_by_manuscript?)
      config.add_show_tools_partial(:deprecate_entry, partial: 'nav/deprecate_entry', if: :show_deprecate_entry?)
      config.add_show_tools_partial(:entry_history, partial: 'nav/entry_history', if: :show_entry_history_link?)
      config.add_show_tools_partial(:export_csv, partial: 'nav/export_csv', if: :show_export_csv_link?)
      #config.add_show_tools_partial(:email)
      #config.add_show_tools_partial(:sms)
      #config.add_show_tools_partial(:citation)
      config.add_show_tools_partial(:verify_entry, partial: 'nav/verify_entry', if: :show_verify_entry?)

    end

    # search_params_logic is an array of SearchBuilder methods that do
    # some processing from Blacklight URL params to Solr params

    self.search_params_logic << :show_all_if_no_query

    self.search_params_logic << :handle_facet_prefix

    self.search_params_logic << :show_approved
    self.search_params_logic << :show_created_by_user
    self.search_params_logic << :show_deprecated

    self.search_params_logic << :translate_manuscript_date
    self.search_params_logic << :translate_provenance_date
    self.search_params_logic << :translate_source_date

  end

end
