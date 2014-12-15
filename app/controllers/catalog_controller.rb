# -*- encoding : utf-8 -*-
#
class CatalogController < ApplicationController  
  include Blacklight::Marc::Catalog

  include Blacklight::Catalog

  self.solr_search_params_logic << :show_all_if_no_query

  # a behavior for solr_search_params: if there's no query, default to
  # showing all results
  def show_all_if_no_query(solr_parameters, user_parameters)
    solr_parameters['q'] = "*" if user_parameters['q'].blank?
  end

  configure_blacklight do |config|
    ## Default parameters to send to solr for all search-like requests. See also SolrHelper#solr_search_params
    config.default_solr_params = { 
      # we load entry fields from db, so these are the only fields we need returned from solr
      :fl => 'id, entry_id_is',
      :qt => 'search',
      :rows => 10,
      'facet.mincount' => 1,
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
    config.index.title_field = 'sdbm_id_ss'
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

    config.add_facet_field 'title_sms', :label => 'Title', :collapse => false, :limit => 3
    config.add_facet_field 'author_sms', :label => 'Authors', :collapse => false, :limit => 3
    config.add_facet_field 'provenance_sms', :label => 'Provenance', :collapse => false, :limit => 3
    config.add_facet_field 'folios_is', :label => 'Folios', :collapse => false, :limit => 3
    config.add_facet_field 'source_ss', :label => 'Source', :limit => 3
    config.add_facet_field 'transaction_seller_agent_ss', :label => 'Seller Agent', :limit => 3
    config.add_facet_field 'transaction_seller_ss', :label => 'Seller', :limit => 3
    config.add_facet_field 'transaction_buyer_ss', :label => 'Buyer', :limit => 3
    config.add_facet_field 'manuscript_sms', :label => 'Manuscript', :limit => 3

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

    # TODO: comments?
    
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
      field.solr_local_parameters = { 
        # default search field
        :df => 'complete_entry_texts',
      }
    end

    config.add_search_field("source_date") do |field|
      field.include_in_simple_select = false
      field.solr_parameters = { :qf => "source_date_texts" }
    end

    config.add_search_field('title') do |field|
      field.solr_local_parameters = {
        :df => 'title_texts',
      }
    end

    config.add_search_field('author') do |field|
      field.solr_local_parameters = {
        :df => 'author_texts',
      }
    end

    config.add_search_field('source') do |field|
      field.solr_local_parameters = {
        :df => 'source_texts',
      }
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

    config.add_sort_field 'entry_id_is asc', :label => 'ID'

    # config.add_sort_field 'score desc, pub_date_sort desc, title_sort asc', :label => 'relevance'
    # config.add_sort_field 'pub_date_sort desc, title_sort asc', :label => 'year'
    # config.add_sort_field 'author_sort asc, title_sort asc', :label => 'author'
    # config.add_sort_field 'title_sort asc, pub_date_sort desc', :label => 'title'

    # If there are more than this many search results, no spelling ("did you 
    # mean") suggestion is offered.
    config.spell_max = 5
  end

end 
