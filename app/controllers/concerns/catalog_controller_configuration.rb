
module CatalogControllerConfiguration

  extend ActiveSupport::Concern

  included do

    configure_blacklight do |config|

      config.max_per_page = 500

      config.solr_response_model = SDBMSS::Blacklight::SolrResponse

      config.document_presenter_class = SDBMSS::Blacklight::DocumentPresenter

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

      # solr path which will be added to solr base url before the other solr params.
      #config.solr_path = 'select' 

      # items to show per page, each number in the array represent another option to choose from.
      #config.per_page = [10,20,50,100]

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

      # solr field configuration for document/show views
      #config.show.title_field = 'title_display'
      #config.show.display_type_field = 'format'

      # solr fields that will be treated as facets by the blacklight application
      #   The ordering of the field names is the order of the display
      #
      # Setting a limit will trigger Blacklight's 'more' facet values link.
      # * If left unset, then all facet values returned by solr will be displayed.
      # * If set to an integer, then "f.somefield.facet.limit" will be added to
      # solr request, with actual solr request being +1 your configured limit --
      # you configure the number of items you actually want _displayed_ in a page.    
      # * If set to 'true', then no additional parameters will be sent to solr,
      # but any 'sniffed' request limit parameters will be used for paging, with
      # paging at requested limit -1. Can sniff from facet.limit or 
      # f.specific_field.facet.limit solr request params. This 'true' config
      # can be used if you set limits in :default_solr_params, or as defaults
      # on the solr side in the request handler itself. Request handler defaults
      # sniffing requires solr requests to be made with "echoParams=all", for
      # app code to actually have it echo'd back to see it.  
      #
      # :show may be set to false if you don't want the facet to be drawn in the 
      # facet bar
      #
      # NOTE: the wiki docs say about the :single option that "Only one
      # value can be selected at a time. When the value is selected, the
      # value of this field is ignored when calculating facet counts for
      # this field." This behavior of facet counts is weird and
      # confusing, so we leave it off.

      config.add_facet_field 'author', :label => 'Author', :collapse => false, :limit => 3
      config.add_facet_field 'title', :label => 'Title', :collapse => false, :limit => 3
      config.add_facet_field 'transaction_seller', :label => 'Seller', :collapse => false, :limit => 3
      config.add_facet_field 'transaction_seller_agent', :label => 'Seller Agent', :collapse => false, :limit => 3
      config.add_facet_field 'transaction_buyer', :label => 'Buyer', :collapse => false, :limit => 3
      # facet on source display str, instead of having separate facets for
      # catalog/catalog date/institution
      config.add_facet_field 'source', :label => 'Source', :collapse => false, :limit => 3
      config.add_facet_field 'provenance', :label => 'Provenance', :limit => 3
      config.add_facet_field 'manuscript_date', :label => 'Manuscript Date', :limit => 3
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

      # config.add_facet_field 'example_pivot_field', :label => 'Pivot Field', :pivot => ['format', 'language_facet']

      # config.add_facet_field 'example_query_facet_field', :label => 'Publish Date', :query => {
      #    :years_5 => { :label => 'within 5 Years', :fq => "pub_date:[#{Time.now.year - 5 } TO *]" },
      #    :years_10 => { :label => 'within 10 Years', :fq => "pub_date:[#{Time.now.year - 10 } TO *]" },
      #    :years_25 => { :label => 'within 25 Years', :fq => "pub_date:[#{Time.now.year - 25 } TO *]" }
      # }


      # Have BL send all facet field names to Solr, which has been the default
      # previously. Simply remove these lines if you'd rather use Solr request
      # handler defaults, or have no facets.
      config.add_facet_fields_to_solr_request!

      # solr fields to be displayed in the index (search results) view
      #   The ordering of the field names is the order of the display 
      # config.add_index_field 'manuscript_id_is', :label => 'Manuscript'
      # config.add_index_field 'source_texts', :label => 'Source'
      # config.add_index_field 'catalog_or_lot_number_ss', :label => 'Cat./Lot #'
      # config.add_index_field 'secondary_source_ss', :label => 'Secondary Source'
      # config.add_index_field 'transaction_seller_agent_ss', :label => 'Seller Agent'
      # config.add_index_field 'transaction_seller_ss', :label => 'Seller'
      # config.add_index_field 'transaction_buyer_ss', :label => 'Buyer'
      # config.add_index_field 'title_sms', :label => 'Titles'
      # config.add_index_field 'author_sms', :label => 'Authors'
      # config.add_index_field 'manuscript_date_display_sms', :label => 'Manuscript Dates'
      # config.add_index_field 'place_sms', :label => 'Places'
      # config.add_index_field 'folios_is', :label => 'Folios'
      # config.add_index_field 'provenance_sms', :label => 'Provenance'
      
      # solr fields to be displayed in the show (single result) view
      #   The ordering of the field names is the order of the display 

      # we can use :link_to_search => true to get search links with that
      # value selected as a facet, but then everything will be linked,
      # and its very distracting and confusing.

      # Source section
      # config.add_show_field 'source_texts', :label => 'Source'
      # config.add_show_field 'catalog_or_lot_number_ss', :label => 'Cat./Lot #'
      # config.add_show_field 'secondary_source_ss', :label => 'Secondary Source'
      # # Transaction section
      # config.add_show_field 'transaction_seller_agent_ss', :label => 'Seller Agent'
      # config.add_show_field 'transaction_seller_ss', :label => 'Seller'
      # config.add_show_field 'transaction_buyer_ss', :label => 'Buyer'
      # config.add_show_field 'transaction_sold_ss', :label => 'Sold'
      # config.add_show_field 'transaction_price_es', :label => 'Price'
      # # Details
      # config.add_show_field 'title_sms', :label => 'Titles'
      # config.add_show_field 'author_sms', :label => 'Authors'
      # config.add_show_field 'manuscript_date_display_sms', :label => 'Manuscript Dates'
      # config.add_show_field 'artist_sms', :label => 'Artists'
      # config.add_show_field 'scribe_sms', :label => 'Scribes'
      # config.add_show_field 'language_sms', :label => 'Languages'
      # config.add_show_field 'material_sms', :label => 'Materials'
      # config.add_show_field 'place_sms', :label => 'Places'
      # config.add_show_field 'use_sms', :label => 'Uses'

      # config.add_show_field 'current_location_ss', :label => 'Current Location'
      # config.add_show_field 'folios_is', :label => 'Folios'
      # config.add_show_field 'num_lines_is', :label => 'Lines'
      # config.add_show_field 'num_columns_is', :label => 'Columns'
      # config.add_show_field 'height_is', :label => 'Height'
      # config.add_show_field 'width_is', :label => 'Width'
      # config.add_show_field 'alt_size_ss', :label => 'Alt Size'
      # config.add_show_field 'miniatures_fullpage_is', :label => 'Miniatures Full-Page'
      # config.add_show_field 'miniatures_large_is', :label => 'Miniatures Large'
      # config.add_show_field 'miniatures_small_is', :label => 'Miniatures Small'
      # config.add_show_field 'miniatures_unspec_size_is', :label => 'Miniatures Unspec Size'
      # config.add_show_field 'initials_historiated_is', :label => 'Historiated Initials'
      # config.add_show_field 'initials_decorated_is', :label => 'Decorated Initials'

      # config.add_show_field 'manuscript_binding_ss', :label => 'MS Binding'
      # config.add_show_field 'manuscript_link_ss', :label => 'MS Link'
      # config.add_show_field 'other_info_ss', :label => 'Other Info'

      # config.add_show_field 'provenance_sms', :label => 'Provenance'

      # config.add_show_field 'comment_sms', :label => 'Comments'

      # "fielded" search configuration. Used by pulldown among other places.
      # For supported keys in hash, see rdoc for Blacklight::SearchFields
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

      # This one uses all the defaults set by the solr request handler. Which
      # solr request handler? The one set in config[:default_solr_parameters][:qt],
      # since we aren't specifying it otherwise. 

      config.add_search_field 'all_fields', :label => 'All Fields' do |field|
        field.solr_local_parameters = { :qf => 'complete_entry' }
      end

      config.add_search_field('title') do |field|
        field.solr_parameters = { :qf => 'title_search' }
      end

      config.add_search_field('author') do |field|
        field.solr_parameters = { :qf => 'author_search' }
      end

      config.add_search_field('source') do |field|
        field.solr_local_parameters = { :qf => 'source_search' }
      end

      config.add_search_field('seller_agent') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'transaction_seller_agent_search' }
      end

      config.add_search_field('seller') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'transaction_seller_search' }
      end

      config.add_search_field('buyer') do |field|
        field.include_in_simple_select = false
        field.solr_local_parameters = { :qf => 'transaction_buyer_search' }
      end

      config.add_search_field('catalog_or_lot_number') do |field|
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

      # TODO: provenance

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

      config.add_search_field('transaction_price') do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'transaction_price' }
      end

      config.add_search_field 'entry_id', :label => 'Entry ID' do |field|
        field.include_in_simple_select = false
        field.is_numeric_field = true
        field.solr_local_parameters = { :qf => 'entry_id' }
      end

      # Specifying a :qt only to show it's possible, and so our internal automated
      # tests can test it. In this case it's the same as 
      # config[:default_solr_parameters][:qt], so isn't actually neccesary. 
      # config.add_search_field('subject') do |field|
      #   field.solr_parameters = { :'spellcheck.dictionary' => 'subject' }
      #   field.qt = 'search'
      #   field.solr_local_parameters = { 
      #     :qf => '$subject_qf',
      #     :pf => '$subject_pf'
      #   }
      # end

      # "sort results by" select (pulldown)
      # label in pulldown is followed by the name of the SOLR field to sort by and
      # whether the sort is ascending or descending (it must be asc or desc
      # except in the relevancy case).

      config.add_sort_field 'entry_id asc', :label => 'ID'

      # config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
      # config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
      # config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
      # config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'

      # If there are more than this many search results, no spelling ("did you 
      # mean") suggestion is offered.
      config.spell_max = 5

      config.add_nav_action(:dashboard, partial: 'nav/dashboard')

      config.add_show_tools_partial(:edit_entry, partial: 'nav/edit_entry', if: :show_edit_link?)

    end

    self.solr_search_params_logic << :show_all_if_no_query

    # a behavior for solr_search_params: if there's no query, default to
    # showing all results
    def show_all_if_no_query(solr_parameters, user_parameters)
      # edismax itself doesn't understand '*' but we can pass in q.alt
      # and it will work for some reason
      solr_parameters['q.alt'] = "*:*" if user_parameters['q'].blank?
    end

  end

end
