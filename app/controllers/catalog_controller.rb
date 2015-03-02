# -*- encoding : utf-8 -*-
#
class CatalogController < ApplicationController  
  include Blacklight::Catalog

  include CatalogControllerConfiguration

  # Overrides Blacklight::Catalog#show to check for existence and send
  # 404 if necessary
  def show
    if Entry.exists?(params[:id])
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
    # don't save searches that return everything
    unless search.query_params["search_field"] == "all_fields" && search.query_params["q"].blank?
      super search
    end
  end

end
