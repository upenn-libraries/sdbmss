class Entry < ActiveRecord::Base

  ALT_SIZE_TYPES = [
    ['F', 'Folio'],
    ['Q', 'Quarto'],
    ['O', 'Octavo'],
    ['12mo', 'Duodecimo or Twelvemo'],
    ['16mo', 'Decimo-sexto or Sixteenmo'],
    ['18mo', 'Decimo-octavo or Eighteenmo'],
    ['24mo', 'Vingesimo-quarto or Twenty-fourmo'],
    ['32mo', 'Trigesimo-secundo or Thirty-twomo'],
    ['48mo', 'Quadragesimo-octavo or Forty-eightmo'],
    ['64mo', 'Sexagesimo-quarto or Sixty-fourmo'],
  ]

  TYPE_TRANSACTION_SALE = 'sale'
  TYPE_TRANSACTION_GIFT = 'gift'
  TYPE_TRANSACTION_NONE = 'no_transaction'

  TYPES_TRANSACTION = [
    [TYPE_TRANSACTION_NONE, 'Not a transaction'],
    [TYPE_TRANSACTION_SALE, 'A Sale'],
    [TYPE_TRANSACTION_GIFT, 'A Gift'],
  ]

  include UserFields
  include Watchable
  include HasPaperTrail
  include HasTouchCount
  include CreatesActivity
  include Notified

  include Ratable
  include TellBunny

  extend SolrSearchable

  belongs_to :source, counter_cache: :entries_count

  # entries have institution/collection for "Other published sources" only
  belongs_to :institution, class_name: "Name"

  has_many :group_records, as: :record
  has_many :group_editable_records, -> { where editable: true}, class_name: "GroupRecord", as: :record
  has_many :editing_groups, through: :group_editable_records, :source => :group
  has_many :groups, through: :group_records
  has_many :group_users,  -> { where confirmed: true }, through: :groups
  has_many :editing_group_users,  -> { where confirmed: true }, through: :editing_groups, :source => :group_users
  has_many :contributors, source: :user, through: :editing_group_users

  belongs_to :superceded_by, class_name: "Entry"
  has_many :supercedes, class_name: "Entry", :foreign_key => :superceded_by_id

  has_many :bookmarks, as: :document, dependent: :destroy
  has_many :bookmarkers, through: :bookmarks, source: :user

  has_many :entry_manuscripts, inverse_of: :entry, dependent: :destroy
  has_many :manuscripts, through: :entry_manuscripts
  has_many :entry_titles, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :entry_authors, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :authors, through: :entry_authors
  has_many :entry_dates, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :entry_artists, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :artists, through: :entry_artists
  has_many :entry_scribes, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :scribes, through: :entry_scribes
  has_many :entry_languages, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :languages, through: :entry_languages
  has_many :entry_materials, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :entry_places, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  has_many :places, through: :entry_places
  has_many :entry_uses, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy
  
#  has_many :entry_comments, dependent: :destroy
  has_many :comments, as: :commentable
  has_many :sales, inverse_of: :entry, dependent: :destroy
  has_many :provenance, -> { order(:order => :asc) }, inverse_of: :entry, dependent: :destroy

  accepts_nested_attributes_for :entry_titles, allow_destroy: true
  accepts_nested_attributes_for :entry_authors, allow_destroy: true
  accepts_nested_attributes_for :entry_dates, allow_destroy: true
  accepts_nested_attributes_for :entry_artists, allow_destroy: true
  accepts_nested_attributes_for :entry_scribes, allow_destroy: true
  accepts_nested_attributes_for :entry_languages, allow_destroy: true
  accepts_nested_attributes_for :entry_materials, allow_destroy: true
  accepts_nested_attributes_for :entry_places, allow_destroy: true
  accepts_nested_attributes_for :entry_uses, allow_destroy: true
  accepts_nested_attributes_for :sales, allow_destroy: true
  accepts_nested_attributes_for :provenance, allow_destroy: true
  accepts_nested_attributes_for :group_records, allow_destroy: true

  # list of args to pass to Entry.includes in various places, for fetching a 'complete' entry
=begin 
  @@includes = [
    :institution,
    :entry_titles,
    :entry_dates,
    :entry_materials,
    :entry_uses,
    :created_by,
    :updated_by,
    :entry_manuscripts => [:manuscript],
    :entry_authors => [:author],
    :entry_artists => [:artist],
    :entry_scribes => [:scribe],
    :entry_languages => [:language],
    :entry_places => [:place],
    :sales => [
      {:sale_agents => [:agent]}
    ],
    :provenance => [:provenance_agent],
    :source => [
      :source_type,
      {:source_agents => [:agent]}
    ]
  ]
=end
  @@includes = [
    # try including bookmarks, watches?
    :created_by, 
    :updated_by, 
    :institution,
    :entry_titles,
    :entry_dates,
    :entry_uses,
    :entry_materials,
    :comments,
    :supercedes,
    :groups,
    :manuscripts,
    {:group_records => [:group]}, 
    {:sales => [:sale_agents => [:agent]]},
    {:entry_authors => [:author]},
    {:entry_artists => [:artist]},
    {:entry_scribes => [:scribe]},
    {:entry_languages => [:language]},
    {:entry_places => [:place => [:parent => [:parent => [:parent => [:parent => [:parent]]]]]]},
    {:provenance => [:provenance_agent]},
    {:entry_manuscripts => [:manuscript]},
    {:source => [:source_agents,:source_type]}
  ]

  default_scope { where(deleted: false) }

  # aggressively load all associations; useful for cases where you
  # want to display the complete info for Entries
  scope :with_associations, -> {
    includes(@@includes)
  }

  # returns 'count' number of most recent entries
  scope :most_recent, ->(count = 5) { order(created_at: :desc, id: :desc).first(count) }

  # returns the entries that have the specified author
  scope :with_author, ->(name) { joins(:entry_authors).where("entry_authors.author_id = #{name.id}").distinct }

  # an agent is a Name object; role is a string
  scope :with_sale_agent_and_role, -> (agent, role) { joins(:sales => :sale_agents).where("deprecated=false and sale_agents.agent_id = ? and role = ?", agent.id, role).distinct }

  scope :approved_only, -> { where(approved: true) }

  # Note that there is separate front-end Javascript/AngularJS code
  # that does validation, which should be kept in sync with the
  # validations here. I haven't found a good way to automatically
  # couple and keep the two sets of validation specifications in sync.

  validates_presence_of :source

  validate do |entry|
    if entry.transaction_type
      source_type = entry.source.source_type
      # validate transaction_type based on source_type
      transaction_field = source_type.entries_transaction_field
      if transaction_field != 'choose' && entry.transaction_type != transaction_field
        errors[:transaction_type] = "transaction_type '#{entry.transaction_type}' isn't valid for source type '#{entry.source.source_type.name}'"
      end
      entries_have_institution_field = source_type.entries_have_institution_field
      if !entries_have_institution_field && entry.institution
        errors[:institution] = "institution field has '#{entry.institution}' but isn't allowed to be populated for source type '#{entry.source.source_type.name}'"
      end
      # make sure it's one of the listed values
      if !TYPES_TRANSACTION.map(&:first).member?(entry.transaction_type)
        errors[:transaction_type] = "transaction_type '#{entry.transaction_type}' isn't in the list of valid values"
      end
    end
  end

  validates_numericality_of :folios, allow_nil: true
  validates_numericality_of :num_lines, allow_nil: true
  validates_numericality_of :num_columns, allow_nil: true
  validates_numericality_of :height, allow_nil: true
  validates_numericality_of :width, allow_nil: true
  validates :alt_size, inclusion: { in: ALT_SIZE_TYPES.map(&:first) }, allow_nil: true
  validates_numericality_of :miniatures_fullpage, allow_nil: true
  validates_numericality_of :miniatures_large, allow_nil: true
  validates_numericality_of :miniatures_small, allow_nil: true
  validates_numericality_of :miniatures_unspec_size, allow_nil: true
  validates_numericality_of :initials_historiated, allow_nil: true
  validates_numericality_of :initials_decorated, allow_nil: true
  validates_length_of :manuscript_binding, maximum: 1024
  validates_length_of :manuscript_link, maximum: 1024

  after_create :update_source_status
  #after_save :update_counters

  def public_id
    SDBMSS::IDS.get_public_id_for_model(self.class, id)
  end

  def manuscript
    entry_manuscripts.select { |em| em.relation_type == EntryManuscript::TYPE_RELATION_IS}.map(&:manuscript).first
  end

  def decrement_counters
    objects = []

    authors.uniq.each do |author|
      Name.decrement_counter(:authors_count, author.id)
      objects.push(author)
    end
    artists.uniq.each do |artist|
      Name.decrement_counter(:artists_count, artist.id)
      objects.push(artist)
    end
    scribes.uniq.each do |scribe|
      Name.decrement_counter(:scribes_count, scribe.id)
      objects.push(scribe)
    end
    provenance.uniq.each do |prov|
      if prov.provenance_agent
        Name.decrement_counter(:provenance_count, prov.provenance_agent_id)
        objects.push(prov.provenance_agent)
      end
    end
    places.uniq.each do |place|
      Place.decrement_counter(:entries_count, place.id)
      objects.push(place)
    end
    languages.uniq.each do |language|
      Language.decrement_counter(:entries_count, language.id)
      objects.push(language)
    end
    
    if sale
      sale.sale_agents.map(&:agent).uniq.each do |sale_agent|
        Name.decrement_counter(:sale_agents_count, sale_agent.id)
        objects.push(sale_agent)
      end
    end
    # sources
    Source.decrement_counter(:entries_count, source.id)
    objects.push(source)

    manuscripts.uniq.each do |mss|
      Manuscript.decrement_counter(:entries_count, mss.id)
      objects.push(mss)
    end

    objects.each(&:index)
  end

  # returns all Entry objects for this entry's Manuscript

  def get_sale
    sales.first
  end

  # returns all Entry objects for this entry's Manuscript
  def get_entries_for_manuscript
    ms = manuscript
    ms ? ms.entries : []
  end

  # new 'get_sale_agent' methods now that an entry can have multiple of each

  def get_sale_agents_names(role)
    t = get_sale
    
    if !t
      return ""
    end

    if role == SaleAgent::ROLE_SELLING_AGENT
      t.get_selling_agents_names
    elsif role == SaleAgent::ROLE_SELLER_OR_HOLDER
      t.get_sellers_or_holders_names
    elsif role == SaleAgent::ROLE_BUYER
      t.get_buyers_names
    end
  end

  def get_sale_selling_agents_names
    get_sale_agents_names(SaleAgent::ROLE_SELLING_AGENT)
  end

  def get_sale_sellers_or_holders_names
    get_sale_agents_names(SaleAgent::ROLE_SELLER_OR_HOLDER)
  end

  def get_sale_buyers_names
    get_sale_agents_names(SaleAgent::ROLE_BUYER)
  end

  def sale
    sales.first
  end

  def sale_agent(role)
    t = sale
    if t
      sa = t.get_sale_agents_with_role(role)
      if sa
        sa.map(&:agent)
      end
    end
  end

  def get_sale_sold
    t = get_sale
    t.sold if t
  end

  def get_sale_price
    t = get_sale
    t.price if t
  end

  def missing_authority_names
    entry_authors.select{ |ea| ea.author_id.blank? && ea.observed_name.present? }.length + 
    entry_artists.select{ |ea| ea.artist_id.blank? && ea.observed_name.present? }.length + 
    entry_scribes.select{ |ea| ea.scribe_id.blank? && ea.observed_name.present? }.length + 
    provenance.select{ |ea| ea.provenance_agent_id.blank? && ea.observed_name.present? }.length
  end

  # returns list of the hashes representing unique Agents found in
  # this Entry's provenance, ordered alphabetically. Each hash
  # has :name key and optionally an :agent key.
  def unique_provenance_agents
    unique_agents = {}
    provenance.order(:order).each do |p|
      agent = p.provenance_agent
      if agent.present?
        unique_agents[agent.id] = {
          agent: agent,
          name: agent.name
        }
      else
        unique_agents[p.observed_name] = {
          name: p.observed_name,
        }
      end
    end
# for sorting alphabetically, if that's what you want
#    unique_agents.values.sort_by { |record| record[:name] }
    unique_agents.values.sort_by { }
  end

  # returns list of provenance names for Solr indexing
  def provenance_names
    names = []
    provenance.each do |provenance_item|
      if provenance_item.provenance_agent
        names << provenance_item.provenance_agent.name
      end
      if provenance_item.observed_name.present?
        names << provenance_item.observed_name
      end
    end
    names
  end

  def to_s
    display_value
  end

  def display_value
    entry_titles.order(:order).map(&:title).join("; ") || "(No title)"
  end

  # returns the most recent updated_at timestamp, as an integer, of
  # this Entry AND all its pertinent associations. Since this is used
  # for the data entry page, this EXCLUDES entry-manuscript links.
  def cumulative_updated_at
    SDBMSS::Util.cumulative_updated_at(
      self,
      [ :entry_titles, :entry_authors, :entry_dates, :entry_artists, :entry_scribes, :entry_languages, :entry_materials, :entry_places, :entry_uses, :sales, :provenance ]
    )
  end

  # details for public display, slimmer than 'as_flat_hash' and without things like user groups included
  def bookmark_details
    results = { 
      manuscript: manuscript ? manuscript.id : nil,
      source_date: SDBMSS::Util.format_fuzzy_date(source.date),
      source_title: source.title,
      source_agent: source.source_agents.map(&:agent).join("; "),
      titles: entry_titles.order(:order).map(&:display_value).join("; "),
      authors: entry_authors.order(:order).map(&:display_value).join("; "),
      dates: entry_dates.order(:order).map(&:display_value).join("; "),
      artists: entry_artists.order(:order).map(&:display_value).join("; "),
      scribes: entry_scribes.order(:order).map(&:display_value).join("; "),
      languages: entry_languages.order(:order).map(&:display_value).join("; "),
      materials: entry_materials.order(:order).map(&:display_value).join("; "),
      places: entry_places.order(:order).map(&:display_value).join("; "),
      uses: entry_uses.order(:order).map(&:use).join("; "),
      other_info: other_info,
      provenance: unique_provenance_agents.map { |unique_agent| unique_agent[:name] }.join("; "),
    }
    (results.select { |k, v| !v.blank? }).transform_keys{ |key| key.to_s.humanize }
  end

  # returns a "complete" representation of this entry, including
  # associated data, as a flat (ie non-nested) Hash. This is used to
  # return rows for the table view, and also used for CSV
  # export. Obviously, decisions have to be made here about how to
  # represent the nested associations for display and there has to be
  # some information tweaking/loss.
  

  def as_flat_hash(options: {})

    # for performance, we avoid using has_many->through associations
    # because they always hit the db and circumvent the preloading
    # done in with_associations scope.

    # FIX ME: missing institution field?

    sale = get_sale
    sale_selling_agents = sale ? sale.sale_agents.select{ |sa| sa.role == "selling_agent" } : []#(sale.get_selling_agents_names if sale && sale.get_selling_agents.count > 0)
    sale_seller_or_holders = sale ? sale.sale_agents.select{ |sa| sa.role == "seller_or_holder" } : [] #(sale.get_sellers_or_holders_names if sale && sale.get_sellers_or_holders.count > 0)
    sale_buyers = sale ? sale.sale_agents.select{ |sa| sa.role == "buyer" } : [] #(sale.get_buyers_names if sale && sale.get_buyers.count > 0)
    flat_hash = {
      id: id,
      manuscript: options[:csv].present? ? (entry_manuscripts.map{ |em| em.manuscript.public_id }.join("; ")) : (entry_manuscripts.length > 0 ? entry_manuscripts.map{ |em| {id: em.manuscript_id, relation: em.relation_type} } : nil),
      groups: options[:csv].present? ? group_records.map{ |group_record| group_record.group.name }.join("; ") : group_records.map{ |group_record| [group_record.group_id, group_record.group.name, group_record.editable] },
      source_date: SDBMSS::Util.format_fuzzy_date(source.date),
      source_title: source.title,
      source_catalog_or_lot_number: catalog_or_lot_number,
      institution: (institution ? institution.to_s : ""),
      sale_selling_agent: sale_selling_agents.map(&:display_value).join("; "),
      sale_seller_or_holder: sale_seller_or_holders.map(&:display_value).join("; "),
      sale_buyer: sale_buyers.map(&:display_value).join("; "),
      sale_sold: (sale.sold if sale),
      sale_date: (SDBMSS::Util.format_fuzzy_date(sale.date) if sale),
      sale_price: (sale.get_complete_price_for_display if sale),
      titles: entry_titles.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      authors: entry_authors.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      dates: entry_dates.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      artists: entry_artists.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      scribes: entry_scribes.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      languages: entry_languages.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      materials: entry_materials.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      places: entry_places.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      uses: entry_uses.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:use).join("; "),
      missing_authority_names: missing_authority_names,
      folios: folios,
      num_columns: num_columns,
      num_lines: num_lines,
      height: height,
      width: width,
      alt_size: alt_size,
      miniatures_fullpage: miniatures_fullpage,
      miniatures_large: miniatures_large,
      miniatures_small: miniatures_small,
      miniatures_unspec_size: miniatures_unspec_size,
      initials_historiated: initials_historiated,
      initials_decorated: initials_decorated,
      manuscript_binding: manuscript_binding,
      manuscript_link: manuscript_link,
      other_info: other_info,
      provenance: provenance.sort{ |a, b| a.order.to_i <=> b.order.to_i }.map(&:display_value).join("; "),
      created_at: created_at ? created_at.to_formatted_s(:date_and_time) : nil,
      created_by: created_by ? created_by.username : "",
      updated_at: updated_at ? updated_at.to_formatted_s(:date_and_time) : nil,
      updated_by: updated_by ? updated_by.username : "",
      approved: approved,
      deprecated: deprecated,
      superceded_by_id: superceded_by_id,
      draft: draft
    }
    if options[:csv].present?
      flat_hash[:coordinates] = entry_places.map(&:place).reject(&:blank?).map{ |p| p.latitude.present? ? "(#{p.latitude},#{p.longitude})" : nil}.reject(&:blank?).join("; ")
    end
    flat_hash
  end

  def search_result_format
    as_flat_hash
  end

  def to_citation
    now = DateTime.now.to_formatted_s(:date_mla)
    "Schoenberg Database of Manuscripts. The Schoenberg Institute for Manuscript Studies, University of Pennsylvania Libraries. Web. #{now}: #{public_id}."
  end

  # Tell Sunspot how to index fields from this model.
  #
  # Note that we do NOT use sunspot's default dynamic fields (which
  # append suffixes like '_is' and '_ss' to solr field
  # names). Instead, we use the :as argument to specify the
  # fieldname. Oddly enough, this isn't in the public documentation,
  # but in the code, see Sunspot::Field#set_indexed_name.
  #
  # :text gets tokenized, :string does NOT. often we need two solr
  # fields for the same piece of data, to support both faceting and
  # keyword searches.
  #
  # auto_index should be set to false (via ENV) to prevent migration
  # script from indexing, but we want it to be ON for normal
  # operation.
  searchable  :unless =>  :deleted, :auto_index => (ENV.fetch('SDBMSS_SUNSPOT_AUTOINDEX', 'true') == 'true'),
             :include => @@includes do

    # Simple wrapper around DSL field definition methods like #text,
    # #string, #integer, etc that configures the field to have a solr
    # fieldname that matches sunspot fieldname (using :as keyword
    # arg). This helps with DRY.
    #
    # field_type should be a symbol that matches a DSL field, like
    # :text or :integer
    

    def define_field(field_type, *args, &block)
      # last argument should be hash of options, so add to it
      args.last[:as] = args[0].to_s
      send(field_type, *args, &block)
    end

    # complete_entry is for general full-text search, so dump
    # everything here
    define_field(:text, :complete_entry, :stored => true) do

      fields = [
        # id() method not available b/c of bug:
        # https://github.com/sunspot/sunspot/issues/331
        @__receiver__.id,
        public_id,
        #manuscript ? manuscript.display_value : nil,
        # source info
        source.display_value,
        source.date,
        catalog_or_lot_number,
        institution ? institution.to_s : "",
        # sale
        sale ? sale.price : ""
      ] +
      (sale ? sale.sale_agents.map(&:display_value) : []) +
      # details
      groups.map(&:name) +
      manuscripts.map(&:public_id) + 
      entry_titles.map(&:display_value) +
      entry_authors.map(&:display_value) +
      entry_dates.map(&:display_value) +
      entry_artists.map(&:display_value) +
      entry_scribes.map(&:display_value) +
      entry_languages.map(&:display_value) +
      entry_materials.map(&:display_value) +
      entry_places.map(&:display_value) + 
      entry_uses.map(&:use) +
      [
        folios,
        num_columns,
        num_lines,
        height,
        width,
        alt_size,
        manuscript_binding,
        other_info,
        manuscript_link,
        miniatures_fullpage,
        miniatures_large,
        miniatures_small,
        miniatures_unspec_size,
        initials_historiated,
        initials_decorated,
      ] +
      # provenance
      provenance.map(&:display_value) +
      supercedes.map(&:id) +
      # comments
      comments.select(&:public).map(&:comment) +
      [created_by ? created_by.username : "", updated_by ? updated_by.username : ""]

      fields.map(&:to_s).select(&:present?).join "\n"
    end

    define_field(:string, :entry, :stored => true) do
      public_id
    end
    # for sorting
    define_field(:integer, :entry_id, :stored => true) do
      @__receiver__.id.to_i
    end

    # full display ID
    define_field(:string, :manuscript, :stored => true) do
      (ms = manuscript) && ms.public_id
    end
    define_field(:integer, :manuscript_id, :stored => true) do
      (ms = manuscript) && ms.id
    end

    define_field(:text, :groups, :stored => true) do
      groups.map(&:name).join("; ")
    end

    #### Source info
    define_field(:string, :source_date, :stored => true) do
      source.date
    end
    define_field(:text, :source_date_search, :stored => true) do
      source.date
    end
    

    define_field(:string, :source, :stored => true) do
      source.public_id
    end
    define_field(:string, :source_display, :stored => true) do
      source.display_value
    end
    define_field(:text, :source_agent, :stored => true) do
      source.source_agents.map(&:facet_value).join("; ")
    end
    define_field(:string, :source_agent_sort, :stored => true) do
      source.source_agents.map(&:facet_value).join("; ")
    end
    define_field(:string, :source_type, :stored => true) do
      source.source_type.display_name
    end
    define_field(:text, :source_search, :stored => true) do
      source.display_value
    end
    define_field(:string, :source_title, :stored => true) do
      source.title
    end

    define_field(:string, :source_institution, :stored => true, :multiple => true) do
      source.get_institutions.map { |i| i.agent ? i.agent.name : "" }
    end

    define_field(:string, :institution, :stored => true, :multiple => false) do
      institution.to_s
      #source.get_institutions.map { |i| i.agent ? i.agent.name : "" } + (institution ? [institution] : [])
      #source.get_institution_as_name.try(:name) || institution.try(:name)
    end
    define_field(:text, :institution_search, :stored => true) do
      institution.to_s
      #source.get_institutions_as_names + (institution ? " #{institution}" : "")
      #source.get_institution_as_name.try(:name) || institution.try(:name)
    end

    # allows for mixed number/character log numbers to be ordered numerically
    define_field(:string, :catalog_or_lot_number_sort, :stored => true) do
      catalog_or_lot_number.to_s.gsub(/[^0-9]/, "").gsub(/(\d+)/, '000000\1').gsub(/0*([0-9]{6,})/, '\1')
    end
    define_field(:string, :catalog_or_lot_number, :stored => true) do
      catalog_or_lot_number
    end
    define_field(:text, :catalog_or_lot_number_search, :stored => true) do
      catalog_or_lot_number
    end

    #### Sale info

    define_field(:string, :sale_selling_agent, :stored => true, :multiple => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "selling_agent" }.select(&:facet_value).map(&:facet_value) : []
    end
    define_field(:text, :sale_selling_agent_search, :stored => true, :more_like_this => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "selling_agent" }.map(&:display_value).join("; ") : ""
    end
    define_field(:string, :sale_selling_agent_flat, :stored => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "selling_agent" }.map(&:display_value).join("; ") : ""
    end

    define_field(:string, :sale_seller, :stored => true, :multiple => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "seller_or_holder" }.select(&:facet_value).map(&:facet_value) : []
    end
    define_field(:text, :sale_seller_search, :stored => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "seller_or_holder" }.map(&:display_value).join("; ") : ""
    end
    define_field(:string, :sale_seller_flat, :stored => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "seller_or_holder" }.map(&:display_value).join("; ") : ""
    end

    define_field(:string, :sale_buyer, :stored => true, :multiple => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "buyer" }.select(&:facet_value).map(&:facet_value) : []
    end

    define_field(:text, :sale_buyer_search, :stored => true) do
#      get_sale_buyers_names
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "buyer" }.map(&:display_value).join("; ") : ""
    end

    define_field(:string, :sale_buyer_flat, :stored => true) do
      (sale = get_sale) ? sale.sale_agents.select { |sa| sa.role == "buyer" }.map(&:display_value).join("; ") : ""
    end

    define_field(:string, :sale_sold, :stored => true) do
      get_sale_sold
    end

    define_field(:string, :sale_date, :stored => true) do
      sale.date if sale
    end

    define_field(:double, :sale_price, :stored => true) do
      get_sale_price
    end

    #### Details

    define_field(:string, :title, :stored => true, :multiple => true) do
      entry_titles.select(&:facet_value).map(&:facet_value)
    end
    define_field(:string, :title_flat,:stored => true) do
      entry_titles.map(&:display_value).join("; ")
    end

    define_field(:text, :title_search, :stored => true, :more_like_this => true) do
      entry_titles.map(&:display_value)
    end

    define_field(:string, :author, :stored => true, :multiple => true) do
      entry_authors.select(&:facet_value).map(&:facet_value)
    end
    define_field(:text, :author_search, :stored => true, :more_like_this => true) do
      entry_authors.map(&:display_value)
    end
    define_field(:string, :author_flat, :stored => true) do
      entry_authors.map(&:display_value).join("; ")
    end

    define_field(:string, :manuscript_date, :stored => true, :multiple => true) do
      entry_dates.select {
        |ed|
        ed.date_normalized_start.present? || ed.date_normalized_end.present?
      }.select {
        |ed|
        retval = true
        if ed.date_normalized_start.to_i > SDBMSS::Blacklight::DATE_RANGE_YEAR_MAX ||
           ed.date_normalized_start.to_i < SDBMSS::Blacklight::DATE_RANGE_YEAR_MIN ||
           ed.date_normalized_end.to_i > SDBMSS::Blacklight::DATE_RANGE_YEAR_MAX ||
           ed.date_normalized_end.to_i < SDBMSS::Blacklight::DATE_RANGE_YEAR_MIN
          Rails.logger.warn "normalized dates for entry #{ed.entry_id} are out of bounds: #{ed.date_normalized_start}, #{ed.date_normalized_end}"
          retval = false
        end
        retval
      }.map {
        |entry_date|
        (entry_date.date_normalized_start.present? ? entry_date.date_normalized_start : SDBMSS::Blacklight::DATE_RANGE_YEAR_MIN.to_s) + " " +
          (entry_date.date_normalized_end.present? ? entry_date.date_normalized_end : SDBMSS::Blacklight::DATE_RANGE_YEAR_MAX.to_s)
      }
    end
    define_field(:string, :manuscript_date_range, :stored => true, :multiple => true) do
      entry_dates.select {
        |ed| ed.date_normalized_start.present? && ed.date_normalized_end.present? &&
          ed.date_normalized_start.to_i >= SDBMSS::Blacklight::DATE_RANGE_YEAR_MIN &&
          ed.date_normalized_end.to_i <= SDBMSS::Blacklight::DATE_RANGE_YEAR_MAX
      }.map { |entry_date|
        entry_date.normalized_date_range_str
      }
    end
    define_field(:string, :manuscript_date_flat, :stored => true) do
      entry_dates.map(&:normalized_date_range_str).join("; ")
    end

    define_field(:text, :manuscript_date_search, :stored => true, :more_like_this => true) do
      entry_dates.map(&:normalized_date_range_str)
    end
    # add date text field, reindex (for MORE_LIKE_THIS suggestions method, seems to be an important consideration)

    define_field(:string, :manuscript_public_id, :stored => true, :multiple => true) do
      manuscripts.map(&:public_id)
    end

    define_field(:string, :artist, :stored => true, :multiple => true) do
      entry_artists.select(&:facet_value).map(&:facet_value)
    end
    
    define_field(:string, :artist_flat, :stored => true) do
      entry_artists.map(&:display_value).join("; ")
    end
    define_field(:text, :artist_search, :stored => true, :more_like_this => true) do
      entry_artists.map(&:display_value)
    end

    define_field(:string, :scribe, :stored => true, :multiple => true) do
      entry_scribes.select(&:facet_value).map(&:facet_value)
    end
    define_field(:string, :scribe_flat, :stored => true) do
      entry_scribes.map(&:display_value).join("; ")
    end
    define_field(:text, :scribe_search, :stored => true, :more_like_this => true) do
      entry_scribes.map(&:display_value)
    end

    define_field(:string, :language, :stored => true, :multiple => true) do
      entry_languages.select(&:facet_value).map(&:facet_value)
    end
    define_field(:string, :language_flat, :stored => true) do
      entry_languages.map(&:display_value).join("; ")
    end
    define_field(:text, :language_search, :stored => true, :more_like_this => true) do
      entry_languages.map(&:display_value)
    end

    define_field(:string, :material, :stored => true, :multiple => true) do
      entry_materials.select(&:facet_value).map(&:facet_value)
    end
    define_field(:string, :material_flat, :stored => true) do
      entry_materials.map(&:display_value).join("; ")
    end
    define_field(:text, :material_search, :stored => true, :more_like_this => true) do
      entry_materials.map(&:display_value)
    end

    define_field(:string, :place, :stored => true, :multiple => true) do
      places.map(&:ancestors).flatten.uniq
    end
    define_field(:string, :place_flat, :stored => true) do
      entry_places.map(&:display_value).join("; ")
    end
    define_field(:text, :place_search, :stored => true, :more_like_this => true) do
      entry_places.map(&:display_value)
    end

    define_field(:string, :use, :stored => true, :multiple => true) do
      entry_uses.map(&:use)
    end
    define_field(:string, :use_flat, :stored => true) do
      entry_uses.map(&:use).join("; ")
    end
    define_field(:text, :use_search, :stored => true, :more_like_this => true) do
      entry_uses.map(&:use)
    end

    define_field(:integer, :supercede, :stored => true, :multiple => true) do
      supercedes.map(&:id)
    end

    define_field(:integer, :superceded_by_id, :stored => true) do
      superceded_by_id
    end

    define_field(:integer, :missing_authority_names, :stored => true) do
      entry_authors.where(author_id: nil).where.not(observed_name: nil).count + 
      entry_artists.where(artist_id: nil).where.not(observed_name: nil).count + 
      entry_scribes.where(scribe_id: nil).where.not(observed_name: nil).count + 
      provenance.where(provenance_agent_id: nil).where.not(observed_name: nil).count
    end

    define_field(:integer, :folios, :stored => true) { folios }
    #define_field(:text, :folios_search, :stored => true, :more_like_this => true) { folios.to_s }
    
    define_field(:integer, :num_columns, :stored => true) { num_columns }

    define_field(:integer, :num_lines, :stored => true) { num_lines }
    define_field(:string, :num_lines_range, :stored => true) { SDBMSS::Util.range_bucket(num_lines) }

    define_field(:integer, :height, :stored => true) { height }
    define_field(:string, :height_range, :stored => true) { SDBMSS::Util.range_bucket(height) }

    define_field(:integer, :width, :stored => true) { width }
    define_field(:string, :width_range, :stored => true) { SDBMSS::Util.range_bucket(width) }

    define_field(:string, :alt_size, :stored => true) { alt_size }

    define_field(:integer, :miniatures_fullpage, :stored => true) { miniatures_fullpage }
    define_field(:string, :miniatures_fullpage_range, :stored => true) { SDBMSS::Util.range_bucket(miniatures_fullpage) }

    define_field(:integer, :miniatures_large, :stored => true) { miniatures_large }
    define_field(:string, :miniatures_large_range, :stored => true) { SDBMSS::Util.range_bucket(miniatures_large) }

    define_field(:integer, :miniatures_small, :stored => true) { miniatures_small }
    define_field(:string, :miniatures_small_range, :stored => true) { SDBMSS::Util.range_bucket(miniatures_small) }

    define_field(:integer, :miniatures_unspec_size, :stored => true) { miniatures_unspec_size }
    define_field(:string, :miniatures_unspec_size_range, :stored => true) { SDBMSS::Util.range_bucket(miniatures_unspec_size) }

    define_field(:integer, :initials_historiated, :stored => true) { initials_historiated }
    define_field(:string, :initials_historiated_range, :stored => true) { SDBMSS::Util.range_bucket(initials_historiated) }

    define_field(:integer, :initials_decorated, :stored => true) { initials_decorated }
    define_field(:string, :initials_decorated_range, :stored => true) { SDBMSS::Util.range_bucket(initials_decorated) }

    define_field(:text, :binding_search, :stored => true) do
      manuscript_binding
    end

    define_field(:string, :binding, :stored => true) do
      manuscript_binding
    end

    define_field(:text, :manuscript_link_search, :stored => true) do
      manuscript_link
    end

    define_field(:string, :manuscript_link, :stored => true) do
      manuscript_link
    end

    define_field(:text, :other_info_search, :stored => true) do
      other_info
    end

    define_field(:string, :other_info, :stored => true) do
      other_info
    end

    define_field(:date, :created_at, :stored => true) { created_at }
    define_field(:string, :created_by, :stored => true) { created_by ? created_by.username : "" }
    define_field(:date, :updated_at, :stored => true) { updated_at }
    define_field(:string, :updated_by, :stored => true) { updated_by ? updated_by.username : "" }
    define_field(:boolean, :approved, :stored => true) { approved }
    define_field(:boolean, :deprecated, :stored => true) { deprecated }
    define_field(:boolean, :draft, :stored => true) { draft }

    #### Provenance

    define_field(:text, :provenance_composite, :stored => true) do
      (((sale = get_sale) ? sale.sale_agents.map(&:display_value) : []) + provenance.map(&:display_value) + (institution ? [institution.to_s] : []) + [source.display_value]).join(" ")
    end

    define_field(:string, :provenance, :stored => true, :multiple => true) do
      provenance.select(&:facet_value).map(&:facet_value)
    end

    define_field(:text, :provenance_search, :more_like_this => true, :stored => true) do
      provenance.map(&:display_value).join("; ")
    end

    define_field(:string, :provenance_flat, :stored => true) do
      provenance.map(&:display_value).join("; ")
    end
    #define_field(:string, :provenance_place, :multiple => true, :stored => true) do
    #  provenance.map(&:provenance_agent).map{ |pa| (pa && pa.associated_place) ? pa.associated_place.name : nil}.reject(&:blank?)
    #end

    define_field(:string, :provenance_date, :stored => true, :multiple => true) do
      # NOTE: this logic is slightly weird, as there may be a start
      # date but no end date, or vice versa.
      provenance.map { | provenance_item|
        retval = nil
        start_date = (provenance_item.start_date_normalized_start || provenance_item.end_date_normalized_start)
        end_date = (provenance_item.start_date_normalized_end || provenance_item.end_date_normalized_end)
        # only take the provenance_items with either a start OR end date
        if start_date.present? || end_date.present?
          # make sure they both have values? TODO: this probably isn't
          # right: if only one date exists, we should probably use
          # that by itself (for end date, we would use that date + 1
          # day)
          start_date = start_date || SDBMSS::Blacklight::DATE_RANGE_FULL_MIN.to_s
          end_date = end_date || SDBMSS::Blacklight::DATE_RANGE_FULL_MAX.to_s

          if SDBMSS::Util.int?(start_date) && SDBMSS::Util.int?(end_date)
            if start_date.to_i <= SDBMSS::Blacklight::DATE_RANGE_FULL_MAX ||
               start_date.to_i >= SDBMSS::Blacklight::DATE_RANGE_FULL_MIN ||
               end_date.to_i <= SDBMSS::Blacklight::DATE_RANGE_FULL_MAX ||
               end_date.to_i >= SDBMSS::Blacklight::DATE_RANGE_FULL_MIN
              retval = "#{start_date} #{end_date}"
            else
              Rails.logger.warn "normalized dates for provenance #{provenance_item.id} are out of bounds: #{start_date}, #{end_date}"
            end
          else
            Rails.logger.warn "non-integer date values for provenance #{provenance_item.id}: #{start_date}, #{end_date}"
          end
        end
        retval
      }.select { |date_range_str|
        date_range_str.present?
      }
    end

    define_field(:text, :comment_search, :stored => true) do
      comments.select(&:public).map(&:comment).join("\n")
    end

  end

  def to_i
    id
  end

  def dispute_reasons
    ["Malicious/misleading data", "I disagree with some of the data", "Other"]
  end  


  def self.do_csv_dump
    params = ActionController::Parameters.new
    
    filename = "#{self.model_name.to_s.pluralize.underscore}.csv"
    path = "public/static/docs/#{filename}"
    offset = 0

    File.delete("#{path}.zip") if File.exist?("#{path}.zip")
    
    objects = []
    headers = nil
    loop do
      s = do_search(params.merge({:limit => 300, :offset => offset, :order => "entry_id asc"}))
      offset += 300
      ids = s.results.map(&:id)
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
  end


  def self.do_csv_search(params, download)
    
    offset = 0
    
    objects = []
    filename = download.filename
    user = download.user
    id = download.id
    path = "tmp/#{id}_#{user}_#{filename}"
    headers = nil
    loop do
      s = do_search(params.merge({:limit => 300, :offset => offset})) # 12-06-17 fix me: add 'order' param if sorting not working properly?
      offset += 300
      ids = s.results.map(&:id)
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
    #download.created_by.notify("Your download '#{download.filename}' is ready.")
  end  

  # I don't love having to duplicate all the fields AGAIN here, but inheriting it all from blacklight doesn't seem to work
  # 
  def self.filters
    [
      ["Entry Id", "entry_id"], 
      ["Manuscript ID", "manuscript_id"], 
      ["Source ID (Full)", "source"], 
      ["Source Date", "source_date"],
      ["Sale Sold", "sale_sold"],
      ["Sale Date", "sale_date"],
      ["Price", "sale_price"], 
      ["Missing Authority Names", "missing_authority_names"],
      ["Folios", "folios"], 
      ["Columns", "num_columns"], 
      ["Lines", "num_lines"], 
      ["Height", "height"], 
      ["Width", "width"], 
      ["Alternate Size", "alt_size"], 
      ["Fullpage Miniatures", "miniatures_fullpage"], 
      ["Large Miniatures", "miniatures_large"], 
      ["Small Miniatures", "miniatures_small"], 
      ["Unspecified Miniatures", "miniatures_unspec_size"], 
      ["Historiated Initals", "initials_historiated"],
      ["Decorated Initials", "initials_decorated"],
      ["Updated By", "updated_by"], 
      ["Created By", "created_by"], 
      ["Approved", "approved"],
      ["Deprecated", "deprecated"],
      ["Draft", "draft"]
    ]
  end

  def self.fields
    [
      ["All Fields", "complete_entry"], 
      ["Source", "source_search"],  
      ["Source Date", "source_date_search"],
      ["Catalog or Lot #", "catalog_or_lot_number_search"],
      ["Institution", "institution_search"], 
      ["Selling Agent", "sale_selling_agent_search"], 
      ["Seller", "sale_seller_search"], 
      ["Buyer", "sale_buyer_search"], 
      ["Title", "title_search"],
      ["Author", "author_search"], 
      ["Date", "manuscript_date_search"],
      ["Artist", "artist_search"], 
      ["Scribe", "scribe_search"], 
      ["Binding", "binding_search"], 
      ["Link", "manuscript_link_search"], 
      ["Other Info", "other_info_search"], 
      ["Language", "language_search"], 
      ["Material", "material_search"], 
      ["Place", "place_search"], 
      ["Use", "use_search"],
      ["Provenance", "provenance_search"],
    ]
  end

  def self.dates
    [
      ["Added On", "created_at"], 
      ["Updated On", "updated_at"]
    ]
  end

  def self.search_fields
    super - ["Deprecated", "deprecated"] - ["Draft", "draft"]
  end

  def self.similar_fields
    [:title_search, :place_search, :language_search, :artist_search, :scribe_search, :use_search, :binding_search, :author_search, :manuscript_date_search, :material_search]
  end

  def create_activity(action_name, current_user, transaction_id)
    if !self.draft
      super(action_name, current_user, transaction_id)
    end
  end

  def to_rdf
    %Q(
      sdbm:entries/#{id}
      a       sdbm:entries
      sdbm:entries_catalog_or_lot_number '#{catalog_or_lot_number}'
      sdbm:entries_folios #{folios}
      sdbm:entries_num_columns #{num_columns}
      sdbm:entries_num_lines #{num_lines}
      sdbm:entries_height #{height}
      sdbm:entries_width #{width}
      sdbm:entries_alt_size '#{alt_size}'
      sdbm:entries_manuscript_binding '#{manuscript_binding}'
      sdbm:entries_other_info '#{other_info}'
      sdbm:entries_manuscript_link '#{manuscript_link}'
      sdbm:entries_miniatures_fullpage #{miniatures_fullpage}
      sdbm:entries_miniatures_large #{miniatures_large}
      sdbm:entries_miniatures_small #{miniatures_small}
      sdbm:entries_miniatures_unspec_size #{miniatures_unspec_size}
      sdbm:entries_initials_historiated #{initials_historiated}
      sdbm:entries_initials_decorated #{initials_decorated}
      sdbm:entries_transaction_type #{transaction_type}
      sdbm:entries_deprecated '#{deprecated}'^^xsd:boolean
      sdbm:entries_unverified_legacy_record '#{unverified_legacy_record}'xsd:boolean
      sdbm:entries_institution_id <https://sdbm.library.upenn.edu/names/#{institution_id}>
      sdbm:entries_superceded_by_id <https://sdbm.library.upenn.edu/entries/#{superceded_by_id}>
      sdbm:entries_source_id <https://sdbm.library.upenn.edu/sources/#{source_id}>
    )
  end

  private

  def update_source_status
    if source.status == Source::TYPE_STATUS_TO_BE_ENTERED
      source.update!(status: Source::TYPE_STATUS_PARTIALLY_ENTERED)
    end
  end

  def update_counters
    # deleting is handled separately (in entries controller) since it is actually a quasi-destroy
    if deleted || deprecated
      return
    end

    entry_authors.group_by(&:author_id).keep_if{ |k, v| v.length >= 1}.each do |k, entry_author|
      author = entry_author.first.author
      Name.update_counters(author.id, :authors_count => author.author_entries.where(deprecated: false, draft: false).count - author.authors_count) unless author.nil?
    end
    entry_artists.group_by(&:artist_id).keep_if{ |k, v| v.length >= 1}.each do |k, entry_artist|
      artist = entry_artist.first.artist
      Name.update_counters(artist.id, :artists_count => artist.artist_entries.where(deprecated: false, draft: false).count - artist.artists_count) unless artist.nil?
    end
    entry_scribes.group_by(&:scribe_id).keep_if{ |k, v| v.length >= 1}.each do |k, entry_scribe|
      scribe = entry_scribe.first.scribe
      Name.update_counters(scribe.id, :scribes_count => scribe.scribe_entries.where(deprecated: false, draft: false).count - scribe.scribes_count) unless scribe.nil?
    end
    # sale agent
    if sale
      sale.sale_agents.group_by(&:agent_id).keep_if{ |k, v| v.length >= 1}.each do |k, sale_agent|
        agent = sale_agent.first.agent
        Name.update_counters(agent.id, :sale_agents_count => agent.sale_entries.where(deprecated: false, draft: false).count - agent.sale_agents_count) unless agent.nil?
      end    
    end

    # place, language FIX ME add these
    entry_places.group_by(&:place_id).keep_if{ |k, v| v.length >= 1}.each do |k, entry_place|
      place = entry_place.first.place
      Place.update_counters(place.id, :entries_count => place.entries.where(deprecated: false, draft: false).uniq.count - place.entries_count) unless place.nil?
    end
    entry_languages.group_by(&:language_id).keep_if{ |k, v| v.length >= 1}.each do |k, entry_language|
      language = entry_language.first.language
      Language.update_counters(language.id, :entries_count => language.entries.where(deprecated: false, draft: false).uniq.count - language.entries_count) unless language.nil?
    end

    # provenance
    provenance.group_by(&:provenance_agent_id).keep_if{ |k, v| v.length >= 1}.each do |k, provenance|
      provenance_agent = provenance.first.provenance_agent
      Name.update_counters(provenance_agent.id, :provenance_count => provenance_agent.provenance_entries.where(deprecated: false, draft: false).count - provenance_agent.provenance_count) unless provenance_agent.nil?
    end
  end

end