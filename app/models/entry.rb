class Entry < ActiveRecord::Base
  belongs_to :source

  include UserFields

  has_many :entry_manuscripts
  has_many :manuscripts, through: :entry_manuscripts
  has_many :entry_titles
  has_many :entry_authors
  has_many :authors, through: :entry_authors
  has_many :entry_dates
  has_many :entry_artists
  has_many :artists, through: :entry_artists
  has_many :entry_scribes
  has_many :scribes, through: :entry_scribes
  has_many :entry_languages
  has_many :languages, through: :entry_languages
  has_many :entry_materials
  has_many :entry_places
  has_many :places, through: :entry_places
  has_many :entry_uses
  has_many :entry_comments
  has_many :events

  validates_presence_of :source

  # aggressively load all associations; useful for cases where you
  # want to display the complete info for Entries
  scope :load_associations, -> {
    includes(:entry_titles,
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
               {:source_agents => [:agent]}
             ]
            )
  }

  # returns 'count' number of most recent entries
  scope :most_recent, ->(count = 5) { order(id: :desc).first(count) }

  # returns the entries that have the specified author
  scope :with_author, ->(author) { joins(:entry_authors).where("entry_authors.author_id = #{author.id}").distinct }

  scope :with_transaction_agent_and_role, ->(agent, role) { joins(:events => :event_agents).where("events.primary = true and event_agents.agent_id = ? and role = ?", agent.id, role) }

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

  def get_public_id
    "SDBM_#{id}"
  end

  def get_manuscript
    entry_manuscripts.select { |em| em.relation_type == EntryManuscript::TYPE_RELATION_IS}.map(&:manuscript).first
  end

  # returns all Entry objects for this entry's Manuscript
  def get_entries_for_manuscript
    manuscript = get_manuscript
    manuscript ? manuscript.entries : []
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

  def get_transaction_seller_agent_name
    get_transaction_agent_name(EventAgent::ROLE_SELLER_AGENT)
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

  def get_provenance
    events.select { |event| !event.primary }
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
  searchable :auto_index => (ENV.fetch('SDBMSS_SUNSPOT_AUTOINDEX', 'true') == 'true') do

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
      [
        # id() method not available b/c of bug:
        # https://github.com/sunspot/sunspot/issues/331
        @__receiver__.id,
        "SBDM_" + @__receiver__.id.to_s,
        # source info
        source.display_value,
        catalog_or_lot_number,
        secondary_source,
        # transaction
        get_transaction_seller_agent_name,
        get_transaction_seller_or_holder_name,
        get_transaction_buyer_name,
        get_transaction_price,
        # details
        entry_titles.map(&:title),
        entry_authors.map(&:observed_name),
        authors.map(&:name),
        entry_dates.map(&:display_value),
        artists.map(&:name),
        scribes.map(&:name),
        languages.map(&:name),
        entry_materials.map(&:material),
        places.map(&:name),
        entry_uses.map(&:use),
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
        # provenance
        get_provenance.map { |p| p.display_value },
        # comments
        entry_comments.select { |ec| ec.public }.map { |ec| ec.comment },
      ].map { |item| item.to_s }.select { |item| (!item.nil?) && (item.length > 0) }.join "\n"
    end

    # for sorting
    define_field(:integer, :entry_id, :stored => true) do
      @__receiver__.id.to_i
    end

    # full display ID
    define_field(:string, :manuscript, :stored => true) do
      (manuscript = get_manuscript) && manuscript.get_public_id
    end
    define_field(:integer, :manuscript_id, :stored => true) do
      (manuscript = get_manuscript) && manuscript.id
    end

    #### Source info

    define_field(:string, :source_date, :stored => true) do
      source.date
    end
    define_field(:string, :source, :stored => true) do
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

    define_field(:string, :transaction_seller_agent, :stored => true) do
      get_transaction_seller_agent_name
    end
    define_field(:text, :transaction_seller_agent_search, :stored => true) do
      get_transaction_seller_agent_name
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
      entry_titles.map &:title
    end
    define_field(:string, :title_flat,:stored => true) do
      entry_titles.map(&:title).join("; ")
    end
    define_field(:text, :title_search, :stored => true) do
      entry_titles.map &:title
    end

    define_field(:string, :author, :stored => true, :multiple => true) do
      authors.map &:name
    end
    define_field(:text, :author_search, :stored => true) do
      authors.map &:name
    end

    # TODO: fiddle with this for a better facet taking into account circa
    define_field(:integer, :manuscript_date, :stored => true, :multiple => true) do
      entry_dates.map &:date
    end
    define_field(:string, :manuscript_date_flat, :stored => true) do
      entry_dates.map(&:date).join("; ")
    end

    define_field(:string, :artist, :stored => true, :multiple => true) do
      artists.map &:name
    end
    define_field(:string, :artist_flat, :stored => true) do
      artists.map(&:name).join("; ")
    end
    define_field(:text, :artist_search, :stored => true) do
      artists.map &:name
    end

    define_field(:string, :scribe, :stored => true, :multiple => true) do
      scribes.map &:name
    end
    define_field(:string, :scribe_flat, :stored => true) do
      scribes.map(&:name).join("; ")
    end
    define_field(:text, :scribe_search, :stored => true) do
      scribes.map &:name
    end

    define_field(:string, :language, :stored => true, :multiple => true) do
      languages.map &:name
    end
    define_field(:string, :language_flat, :stored => true) do
      languages.map(&:name).join("; ")
    end
    define_field(:text, :language_search, :stored => true) do
      languages.map &:name
    end

    define_field(:string, :material, :stored => true, :multiple => true) do
      entry_materials.map &:material
    end
    define_field(:string, :material_flat, :stored => true, :multiple => true) do
      entry_materials.map(&:material).join("; ")
    end
    define_field(:text, :material_search, :stored => true) do
      entry_materials.map &:material
    end

    define_field(:string, :place, :stored => true, :multiple => true) do
      places.map &:name
    end
    define_field(:string, :place_flat, :stored => true) do
      places.map(&:name).join("; ")
    end
    define_field(:text, :place_search, :stored => true) do
      places.map &:name
    end

    define_field(:string, :use, :stored => true, :multiple => true) do
      entry_uses.map &:use
    end
    define_field(:string, :use_flat, :stored => true) do
      entry_uses.map(&:use).join("; ")
    end
    define_field(:text, :use_search, :stored => true) do
      entry_uses.map &:use
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
      events = get_provenance
      names = []
      events.each { |event|
        event.event_agents.each { |ea|
          if ea.observed_name.present?
            names << ea.observed_name
          end
          if ea.agent
            names << ea.agent.name
          end
        }
      }
      names if names.length > 0
    end

    define_field(:text, :comment_search, :stored => true) do
      entry_comments.select(&:public).map(&:comment).join("\n")
    end

  end

end
