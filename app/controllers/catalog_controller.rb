# -*- encoding : utf-8 -*-
#
class CatalogController < ApplicationController  
  include Blacklight::Catalog

  include CatalogControllerConfiguration

  # Overrides Blacklight::Catalog#show to check for existence and send
  # 404 if necessary
  def show
    entry = Entry.find_by(id: params[:id], approved: true)
    if entry.present?
      @entry_comment = EntryComment.new(entry: entry)
      @entry_comment.build_comment
      super
    else
      render_404
    end
  end

  # This override sets username field when devise creates the guest
  # user account. This gets called by BookmarksController (which
  # inherits from CatalogController) and possibly other code.
  def create_guest_user email = nil
    # it sucks that most of this is copied over from
    # DeviseGuests::Controllers::Helpers.define_helpers but I can't
    # figure out a better way to shoehorn the change to username into
    # the original code.
    username = "guest_" + guest_user_unique_suffix
    email &&= nil unless email.to_s.match(/^guest/)
    email ||= "#{username}@example.com"
    u = User.new.tap do |g|
      g.email = email
      g.username = username
      g.save
    end
    u.password = u.password_confirmation = email
    u.guest = true if u.respond_to? :guest
    u
  end

  # Overrides Blacklight::Catalog::SearchContext#add_to_search_history
  def add_to_search_history search
    # only add to search history (ie. call this method in the
    # superclass) if the user provided some search parameters
    if search.query_params["search_field"] != "advanced"
      if search.query_params["q"].present?
        super search
      end
    else
      empty = true
      advanced_query.config.search_fields.select do |key, field_def|
        if search.query_params[key].present?
          empty = false
        end
      end
      if !empty
        super search
      end
    end
  end

  # Blacklight::RequestBuilders#solr_facet_params uses this method, if
  # defined, when querying solr and displaying the list of facet values.
  def facet_list_limit
    return params[:limit] || 100
  end

  # required by CatalogControllerConfiguration
  def search_results_max
    Rails.configuration.sdbmss_max_search_results
  end

  # required by CatalogControllerConfiguration
  def search_model_class
    Entry
  end

  # returns a URL for the current search, in CSV format. I's safe to
  # embed this URL in a page; if users manually tweak the per_page
  # param to try to get more results, blacklight will complain, since
  # the max is specified in the BL config.
  def search_results_as_csv_path
    p = params.dup
    p.delete "page"
    p["per_page"] = search_results_max
    p["format"] = "csv"
    sdbmss_search_action_path(p)
  end

  helper_method :search_results_as_csv_path

end
