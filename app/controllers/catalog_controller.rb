# -*- encoding : utf-8 -*-
#
# THIS HAS NOTHING TO DO WITH 'CATALOGS'!
#
# This is called 'CatalogController' because that's what Blacklight
# requires us to call its search controller; it's not customizable
# (because the name is tied to the views directory).
class CatalogController < ApplicationController  
  include Blacklight::Catalog

  include CatalogControllerConfiguration

  rescue_from Blacklight::Exceptions::InvalidRequest, with: :render_bad_search

  #layout "home", :only => [:index]
  #authorize_resource :only => [:show], :class => Entry

  # Overrides Blacklight::Catalog#show to check for existence and send
  # 404 if necessary

  def show
    @entry = Entry.find_by(id: params[:id])
    #if @entry.manuscripts.count <= 0
    #end
    entry = @entry
    # JIRA(sdbm-176)
#    entry = Entry.find_by(id: params[:id], approved: true)
    if entry.present?
=begin
    s = Sunspot.more_like_this(@entry) do
      fields :title_search, :place_search, :author_search, :language_search, :manuscript_date_search, :folios_search
      # without :id, [collect entry_ids from manuscript]
      #minimum_term_frequency 3
      boost_by_relevance true
      order_by :score, :desc
      paginate :per_page => 10, :page => 1
    end
    @suggestions = s.results.first(10)
=end
      @linked = @entry.manuscript ? @entry.manuscript.entries.map(&:id) : []
      if can? :show, entry
        
        @linked = @entry.manuscript ? @entry.manuscript.entries.map(&:id) : []
        s = Sunspot.more_like_this(@entry) do
          fields :title_search, :place_search, :author_search, :language_search
          # without :id, [collect entry_ids from manuscript]
          #minimum_term_frequency 3
          boost_by_relevance true
          order_by :score, :desc
        end
        @suggestions = []#s.results.last(10)
    
        super
        respond_to do |format|
          format.html
        end
      else
        render_access_denied      
      end
    else
      render "not_found.html", status: 404
    end
  end

  def index
    respond_to do |format|
      #format.rss { redirect_to feed_path(format: :rss) }
      #format.atom {redirect_to feed_path(format: :rss) }
      format.html { super }
      format.json { super }
      format.csv { 
        if current_user.downloads.count >= 5
          render json: {error: 'at limit'}
          return
        else
          @d = Download.create({filename: "entries.csv", user_id: current_user.id})
          CatalogController.new.delay.do_csv_search(params, search_params_logic, @d)
          render json: {id: @d.id, filename: @d.filename, count: current_user.downloads.count} 
        end
      }
    end
  end

  def legacy
    host = request.host
    forwarded_host = "sdbm.library.upenn.edu" #request.env["HTTP_X_FORWARDED_SERVER"]
    announcement = '<p class="text-center"><span class="h3">Welcome to the new Schoenberg Database of Manuscripts</span></p>'
    entry_id = params[:id].to_s.include?('SCHOENBERG_') ? params[:id].to_s.gsub('SCHOENBERG_', '') : nil
    if entry_id.present?
      if Entry.exists? entry_id
        announcement += "<p class='text-center'>SCHOENBERG_#{entry_id} no longer exists. It is now SDBM_#{entry_id} and may have been edited since the old SDBM was transferred to the new SDBM in October 2015. The old website is no longer active.</p>"
      else
        announcement += "<p class='text-center'>The page you are looking for cannot be found.  If you know the ID of the record you are looking for, try searching in the top search-bar.</p>"
      end
      flash[:announce] = announcement.html_safe
      redirect_to entry_url(entry_id, host: forwarded_host), status: 301
    elsif params[:path] == "index"
      redirect_to root_url.gsub(host.to_s, forwarded_host.to_s)
    elsif host != forwarded_host
      announcement = %q(
        <p><b>Original query paremeters </b></p>)
      params.except(:controller, :action, :format).each do |key, value|
        announcement += "<p><b>#{key}:</b> #{value}</p>"
      end
      flash.now[:announce] = announcement.html_safe
      #logger.error "HOST: #{host}, FORWARDED_HOST: #{forwarded_host}"
      @link = root_url.gsub(host.to_s, forwarded_host.to_s)
      @host = forwarded_host
      # needs to render without normal layout
      render "legacy", status: 404, layout: false
    end
  end

  def do_csv_search(params, search_params_logic, download)
    # merge per-page params

    page = 1
    
    objects = []
    filename = download.filename
    user = download.user
    id = download.id
    path = "tmp/#{id}_#{user}_#{filename}"
    headers = nil
    
    loop do
      (@response, @document_list) = search_results(params.merge({:page => page, :per_page => 100}), search_params_logic)
      #s = do_search(params.merge({:limit => 300, :offset => offset}))
      page += 1
      ids = @response.response["docs"].map { |doc| doc["entry_id"] }
      #objects = objects + Entry.includes(:sales, :entry_authors, :entry_titles, :entry_dates, :entry_artists, :entry_scribes, :entry_languages, :entry_places, :provenance, :entry_uses, :entry_materials, :entry_manuscripts, :source).includes(:authors, :artists, :scribes, :manuscripts, :languages, :places).where(id: ids).map { |e| e.as_flat_hash }
      objects = Entry.with_associations.where(id: ids).map { |e| e.as_flat_hash({options: {csv: true}}) }
      break if objects.first.nil?
      csv_file = CSV.open(path, "ab") do |csv|
        if headers.nil? && objects.first
          headers = objects.first.keys
          csv << headers
        end
        objects.each do |r|
          csv << r.values 
        end
      end
    end

    Zip::File.open("#{path}.zip", Zip::File::CREATE) do |zipfile|
      zipfile.add(filename, path)
    end

    File.delete(path) if File.exist?(path)

    download.update({status: 1, filename: "#{filename}.zip"})
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

  # override blacklight method to require that user is logged in
  # 
  # this is a workaround to prevent bots from exploding the database with too many (saved) searches
  def find_or_initialize_search_session_from_params params
    if !current_user
      return
    else
      super params
    end
  end

  raise "#add_to_search_history not defined in superclass" if !method_defined?(:add_to_search_history)
  # Overrides Blacklight::Catalog::SearchContext#add_to_search_history
  def add_to_search_history search
    if !current_user
      return
    end
    # only add to search history (ie. call this method in the
    # superclass) if the user provided some search parameters
    if search.query_params["search_field"] != "advanced"
      if search.query_params["q"].present? or search.query_params["f"].present?
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

  # required by CatalogControllerConfiguration  --> change to allow unlimited size searches
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

  def render_bad_search
    respond_to do |format|
      format.html {
        flash[:error] = "Sorry, I don't understand your search."
        redirect_to root_path        
      }
      format.json {
        render json: { error: "Sorry, I don't understand your search." }
      }
    end
  end

end
