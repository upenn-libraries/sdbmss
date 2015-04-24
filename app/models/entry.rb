class Entry < ActiveRecord::Base

  default_scope { where(deleted: false) }

  belongs_to :source, counter_cache: :entries_count

  # entries have institution/collection for "Other published sources" only
  belongs_to :institution, class_name: "Name"

  include UserFields

  has_many :entry_manuscripts
  has_many :manuscripts, through: :entry_manuscripts
  has_many :entry_titles, inverse_of: :entry
  has_many :entry_authors, inverse_of: :entry
  has_many :authors, through: :entry_authors
  has_many :entry_dates, inverse_of: :entry
  has_many :entry_artists, inverse_of: :entry
  has_many :artists, through: :entry_artists
  has_many :entry_scribes, inverse_of: :entry
  has_many :scribes, through: :entry_scribes
  has_many :entry_languages, inverse_of: :entry
  has_many :languages, through: :entry_languages
  has_many :entry_materials, inverse_of: :entry
  has_many :entry_places, inverse_of: :entry
  has_many :places, through: :entry_places
  has_many :entry_uses, inverse_of: :entry
  has_many :entry_comments
  has_many :events, inverse_of: :entry

  accepts_nested_attributes_for :entry_titles, allow_destroy: true
  accepts_nested_attributes_for :entry_authors, allow_destroy: true
  accepts_nested_attributes_for :entry_dates, allow_destroy: true
  accepts_nested_attributes_for :entry_artists, allow_destroy: true
  accepts_nested_attributes_for :entry_scribes, allow_destroy: true
  accepts_nested_attributes_for :entry_languages, allow_destroy: true
  accepts_nested_attributes_for :entry_materials, allow_destroy: true
  accepts_nested_attributes_for :entry_places, allow_destroy: true
  accepts_nested_attributes_for :entry_uses, allow_destroy: true
  accepts_nested_attributes_for :events, allow_destroy: true

  # list of args to pass to Entry.includes in various places, for fetching a 'complete' entry
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
    :events => [
      {:event_agents => [:agent]}
    ],
    :source => [
      :source_type,
      {:source_agents => [:agent]}
    ]
  ]

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
  scope :with_transaction_agent_and_role, ->(agent, role) { joins(:events => :event_agents).where("events.primary = true and event_agents.agent_id = ? and role = ?", agent.id, role) }

  has_paper_trail skip: [:created_at, :updated_at]

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
    [TYPE_TRANSACTION_SALE, 'A Sale'],
    [TYPE_TRANSACTION_GIFT, 'A Gift'],
    [TYPE_TRANSACTION_NONE, 'Not a transaction'],
  ]

  validates_presence_of :source

  validate do |entry|
    if entry.transaction_type
      # validate transaction_type based on source_type
      transaction_field = entry.source.source_type.entries_transaction_field
      if transaction_field != 'choose' && entry.transaction_type != transaction_field
        errors[:transaction_type] = "transaction_type '#{entry.transaction_type}' isn't valid for source type '#{entry.source.source_type.name}'"
      end
      # make sure it's one of the listed values
      if !TYPES_TRANSACTION.map(&:first).member?(entry.transaction_type)
        errors[:transaction_type] = "transaction_type '#{entry.transaction_type}' isn't in the list of valid values"
      end
    end
  end

  def public_id
    "SDBM_#{id}"
  end

  # Returns an array of similar Entry IDs
  def similar
    candidate_ids = Set.new
    SDBMSS::SimilarEntries.new(self).each do |similar_entry|
      entry = similar_entry[:entry]
      candidate_ids.add entry.id
    end
    candidate_ids
  end

  def manuscript
    entry_manuscripts.select { |em| em.relation_type == EntryManuscript::TYPE_RELATION_IS}.map(&:manuscript).first
  end

  # returns all Entry objects for this entry's Manuscript
  def get_entries_for_manuscript
    ms = manuscript
    ms ? ms.entries : []
  end

  def get_num_entries_for_manuscript
    get_entries_for_manuscript.count
  end

  def get_transaction
    events.select { |event| event.primary }.first
  end

  def get_transaction_agent_name(role)
    t = get_transaction
    if t
      ea = t.get_event_agent_with_role(role)
      if ea && ea.agent
        return ea.agent.name
      end
    end
  end

  def get_transaction_selling_agent_name
    get_transaction_agent_name(EventAgent::ROLE_SELLING_AGENT)
  end

  def get_transaction_seller_or_holder_name
    get_transaction_agent_name(EventAgent::ROLE_SELLER_OR_HOLDER)
  end

  def get_transaction_buyer_name
    get_transaction_agent_name(EventAgent::ROLE_BUYER)
  end

  def get_transaction_sold
    t = get_transaction
    t.sold if t
  end

  def get_transaction_price
    t = get_transaction
    t.price if t
  end

  def provenance
    events.select { |event| !event.primary }
  end

  # returns list of the hashes representing unique Agents found in
  # this Entry's provenance, ordered alphabetically. Each hash
  # has :name key and optionally an :agent key.
  def unique_provenance_agents
    unique_agents = {}
    provenance.each do |event|
      event.event_agents.each do |event_agent|
        agent = event_agent.agent
        if agent.present?
          unique_agents[agent.id] = {
            agent: agent,
            name: agent.name
          }
        else
          unique_agents[event_agent.observed_name] = {
            name: event_agent.observed_name,
          }
        end
      end
    end
    unique_agents.values.sort_by { |record| record[:name] }
  end

  # returns list of provenance names for Solr indexing
  def provenance_names
    events = provenance
    names = []
    events.each { |event|
      event.event_agents.select(&:is_provenance).each { |ea|
        if ea.agent
          names << ea.agent.name
        end
      }
    }
    names
  end

  # returns the most recent updated_at timestamp, as an integer, of
  # this Entry AND all its pertinent associations. This is used as a
  # mechanism to prevent the user from saving changes when another
  # change was made to the data.
  def cumulative_updated_at
    most_recent = updated_at.to_i
    associations = [ :entry_titles, :entry_authors, :entry_dates, :entry_artists, :entry_scribes, :entry_languages, :entry_materials, :entry_places, :entry_uses, :events ]
    associations.each do |association|
      records = send(association)
      records.each do |record|
        if record.respond_to?(:updated_at)
          record_updated_at = record.updated_at.to_i
          if record_updated_at > most_recent
            most_recent = record_updated_at
          end
        end
      end
    end
    most_recent || 0
  end

  # returns a "complete" representation of this entry, including
  # associated data, as a flat (ie non-nested) Hash. This is used to
  # return rows for the table view, and also used for CSV
  # export. Obviously, decisions have to be made here about how to
  # represent the nested associations for display and there has to be
  # some information tweaking/loss.
  def as_flat_hash
    dateformat = "%Y-%m-%d %I:%M%P"

    # for performance, we avoid using has_many->through associations
    # because they always hit the db and circumvent the preloading
    # done in with_associations scope.

    transaction = get_transaction
    transaction_selling_agent = (transaction.get_selling_agent_as_name.name if transaction && transaction.get_selling_agent_as_name)
    transaction_seller_or_holder = (transaction.get_seller_or_holder_as_name.name if transaction && transaction.get_seller_or_holder_as_name)
    transaction_buyer = (transaction.get_buyer_as_name.name if transaction && transaction.get_buyer_as_name)
    {
      id: id,
      manuscript: manuscript ? manuscript.id : nil,
      source_date: source.date ? SDBMSS::Util.format_fuzzy_date(source.date) : nil,
      source_title: source.title,
      source_catalog_or_lot_number: catalog_or_lot_number,
      secondary_source: secondary_source,
      transaction_selling_agent: transaction_selling_agent,
      transaction_seller_or_holder: transaction_seller_or_holder,
      transaction_buyer: transaction_buyer,
      transaction_sold: (transaction.sold if transaction),
      transaction_price: (transaction.get_price_for_display if transaction),
      titles: entry_titles.map(&:title).join("; "),
      authors: entry_authors.map(&:display_value).join("; "),
      dates: entry_dates.map(&:display_value).join("; "),
      artists: entry_artists.map(&:display_value).join("; "),
      scribes: entry_scribes.map(&:display_value).join("; "),
      languages: entry_languages.map(&:language).map(&:name).join("; "),
      materials: entry_materials.map(&:material).join("; "),
      places: entry_places.map(&:place).map(&:name).join("; "),
      uses: entry_uses.map(&:use).join("; "),
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
      provenance: unique_provenance_agents.map { |unique_agent| unique_agent[:name] }.join("; "),
      created_at: created_at ? created_at.strftime(dateformat) : nil,
      created_by: (created_by.username if created_by),
      updated_at: updated_at ? updated_at.strftime(dateformat) : nil,
      updated_by: (updated_by.username if updated_by),
      approved: approved
    }
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
  searchable :auto_index => (ENV.fetch('SDBMSS_SUNSPOT_AUTOINDEX', 'true') == 'true'),
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
        manuscript ? manuscript.display_value : nil,
        # source info
        source.display_value,
        catalog_or_lot_number,
        secondary_source,
        # transaction
        get_transaction_selling_agent_name,
        get_transaction_seller_or_holder_name,
        get_transaction_buyer_name,
        get_transaction_price
      ] +
      # details
      entry_titles.map(&:display_value) +
      entry_authors.map(&:display_value) +
      entry_dates.map(&:display_value) +
      entry_artists.map(&:display_value) +
      entry_scribes.map(&:display_value) +
      languages.map(&:name) +
      entry_materials.map(&:material) +
      places.map(&:name) +
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
      provenance_names +
      # comments
      entry_comments.select { |ec| ec.public }.map { |ec| ec.comment }

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

    #### Source info

    define_field(:string, :source_date, :stored => true) do
      source.date
    end
    define_field(:string, :source, :stored => true) do
      source.public_id
    end
    define_field(:string, :source_display, :stored => true) do
      source.display_value
    end
    define_field(:text, :source_search, :stored => true) do
      source.display_value
    end
    define_field(:string, :source_title, :stored => true) do
      source.title
    end

    define_field(:string, :catalog_or_lot_number, :stored => true) do
      catalog_or_lot_number
    end
    define_field(:text, :catalog_or_lot_number_search, :stored => true) do
      catalog_or_lot_number
    end
    define_field(:text, :secondary_source_search, :stored => true) do
      secondary_source
    end

    #### Transaction info

    define_field(:string, :transaction_selling_agent, :stored => true) do
      get_transaction_selling_agent_name
    end
    define_field(:text, :transaction_selling_agent_search, :stored => true) do
      get_transaction_selling_agent_name
    end

    define_field(:string, :transaction_seller, :stored => true) do
      get_transaction_seller_or_holder_name
    end
    define_field(:text, :transaction_seller_search, :stored => true) do
      get_transaction_seller_or_holder_name
    end

    define_field(:string, :transaction_buyer, :stored => true) do
      get_transaction_buyer_name
    end
    define_field(:text, :transaction_buyer_search, :stored => true) do
      get_transaction_buyer_name
    end

    define_field(:string, :transaction_sold, :stored => true) do
      get_transaction_sold
    end

    define_field(:double, :transaction_price, :stored => true) do
      get_transaction_price
    end

    #### Details

    define_field(:string, :title,:stored => true, :multiple => true) do
      entry_titles.map(&:title)
    end
    define_field(:string, :title_flat,:stored => true) do
      entry_titles.map(&:title).join("; ")
    end
    define_field(:text, :title_search, :stored => true) do
      entry_titles.map(&:display_value)
    end

    define_field(:string, :author, :stored => true, :multiple => true) do
      authors.map(&:name)
    end
    define_field(:text, :author_search, :stored => true) do
      entry_authors.map(&:display_value)
    end

    define_field(:string, :manuscript_date, :stored => true, :multiple => true) do
      entry_dates.select {
        |ed|
        ed.date_normalized_start.present? || ed.date_normalized_end.present?
      }.map {
        |entry_date|
        (entry_date.date_normalized_start || SDBMSS::Blacklight::DATE_RANGE_YEAR_MIN.to_s) + " " +
          (entry_date.date_normalized_end || SDBMSS::Blacklight::DATE_RANGE_YEAR_MAX.to_s)
      }
    end
    define_field(:string, :manuscript_date_range, :stored => true, :multiple => true) do
      entry_dates.select {
        |ed| ed.date_normalized_start.present? && ed.date_normalized_end.present? &&
          ed.date_normalized_start.to_i >= SDBMSS::Blacklight::DATE_RANGE_YEAR_MIN &&
          ed.date_normalized_end.to_i <= SDBMSS::Blacklight::DATE_RANGE_YEAR_MAX
      }.map { |entry_date|
        if entry_date.date_normalized_start != entry_date.date_normalized_end
          entry_date.date_normalized_start + " - " + entry_date.date_normalized_end
        else
          entry_date.date_normalized_start
        end
      }
    end
    define_field(:string, :manuscript_date_flat, :stored => true) do
      entry_dates.map(&:date).join("; ")
    end

    define_field(:string, :artist, :stored => true, :multiple => true) do
      artists.map(&:name)
    end
    define_field(:string, :artist_flat, :stored => true) do
      artists.map(&:name).join("; ")
    end
    define_field(:text, :artist_search, :stored => true) do
      entry_artists.map(&:display_value)
    end

    define_field(:string, :scribe, :stored => true, :multiple => true) do
      scribes.map(&:name)
    end
    define_field(:string, :scribe_flat, :stored => true) do
      scribes.map(&:name).join("; ")
    end
    define_field(:text, :scribe_search, :stored => true) do
      entry_scribes.map(&:display_value)
    end

    define_field(:string, :language, :stored => true, :multiple => true) do
      languages.map(&:name)
    end
    define_field(:string, :language_flat, :stored => true) do
      languages.map(&:name).join("; ")
    end
    define_field(:text, :language_search, :stored => true) do
      languages.map(&:name)
    end

    define_field(:string, :material, :stored => true, :multiple => true) do
      entry_materials.map(&:material)
    end
    define_field(:string, :material_flat, :stored => true, :multiple => true) do
      entry_materials.map(&:material).join("; ")
    end
    define_field(:text, :material_search, :stored => true) do
      entry_materials.map(&:material)
    end

    define_field(:string, :place, :stored => true, :multiple => true) do
      places.map(&:name)
    end
    define_field(:string, :place_flat, :stored => true) do
      places.map(&:name).join("; ")
    end
    define_field(:text, :place_search, :stored => true) do
      places.map(&:name)
    end

    define_field(:string, :use, :stored => true, :multiple => true) do
      entry_uses.map(&:use)
    end
    define_field(:string, :use_flat, :stored => true) do
      entry_uses.map(&:use).join("; ")
    end
    define_field(:text, :use_search, :stored => true) do
      entry_uses.map(&:use)
    end

    define_field(:integer, :folios, :stored => true) { folios }
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

    define_field(:date, :created_at, :stored => true) { created_at }
    define_field(:string, :created_by, :stored => true) { created_by }
    define_field(:date, :updated_at, :stored => true) { updated_at }
    define_field(:string, :updated_by, :stored => true) { updated_by }
    define_field(:boolean, :approved, :stored => true) { approved }

    #### Provenance

    define_field(:string, :provenance, :stored => true, :multiple => true) do
      provenance_names
    end

    define_field(:text, :provenance_search, :stored => true) do
      provenance_names
    end

    define_field(:text, :comment_search, :stored => true) do
      entry_comments.select(&:public).map(&:comment).join("\n")
    end

  end

end
