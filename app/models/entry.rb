class Entry < ActiveRecord::Base
  belongs_to :source
  belongs_to :created_by, class_name: 'User'
  belongs_to :updated_by, class_name: 'User'

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

  # aggressively load all associations; useful for cases when you need to display complete info for the Entry
  # TODO: fill this out
  scope :load_associations, -> { includes(:entry_authors, :entry_dates, :entry_titles, :entry_places => [:place], :events => [{:event_agents => [:agent]} ], :source => [{:source_agents => [:agent]}]) }

  # returns 'count' number of most recent entries
  scope :most_recent, ->(count = 5) { order(created_at: :desc).first(count) }

  # returns the entries that have the specified author
  scope :with_author, ->(author) { joins(:entry_authors).where("entry_authors.author_id = #{author.id}").distinct }

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
    manuscripts.first
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
  #  TODO: set auto_index to false to prevent migration script from
  #  indexing, but we want it to be ON for normal operation. how to do
  #  this?
  searchable :auto_index => false do

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
        source.get_display_value,
        catalog_or_lot_number,
        secondary_source,
        current_location,
        # transaction
        get_transaction_seller_agent_name,
        get_transaction_seller_or_holder_name,
        get_transaction_buyer_name,
        get_transaction_price,
        # details
        entry_titles.map(&:title),
        authors.map(&:name),
        entry_dates.map(&:get_display_value),
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
        get_provenance.map { |p| p.get_display_value },
        # comments
        entry_comments.select { |ec| ec.public }.map { |ec| ec.comment },
      ].map { |item| item.to_s }.select { |item| (!item.nil?) && (item.length > 0) }.join "\n"
    end

    # for sorting
    define_field(:integer, :entry_id, :stored => true) do
      @__receiver__.id.to_i
    end

    define_field(:string, :manuscript_facet, :stored => true, :multiple => true) do
      entry_manuscripts.map { |em| em.manuscript.get_public_id }
    end

    #### Source info

    define_field(:text, :source, :stored => true) do
      source.get_display_value
    end
    define_field(:string, :source_facet, :stored => true) do
      source.get_display_value
    end
    define_field(:text, :source_date, :stored => true) do
      # TODO: split this up?
      source.date
    end

    define_field(:text, :catalog_or_lot_number, :stored => true)
    define_field(:text, :secondary_source, :stored => true)
    define_field(:text, :current_location, :stored => true)

    #### Transaction info

    define_field(:string, :transaction_seller_agent_facet, :stored => true) do
      get_transaction_seller_agent_name
    end
    define_field(:text, :transaction_seller_agent, :stored => true) do
      get_transaction_seller_agent_name
    end

    define_field(:string, :transaction_seller_facet, :stored => true) do
      get_transaction_seller_or_holder_name
    end
    define_field(:text, :transaction_seller, :stored => true) do
      get_transaction_seller_or_holder_name
    end

    define_field(:string, :transaction_buyer_facet, :stored => true) do
      get_transaction_buyer_name
    end
    define_field(:text, :transaction_buyer, :stored => true) do
      get_transaction_buyer_name
    end

    define_field(:string, :transaction_sold_facet, :stored => true) do
      get_transaction_sold
    end

    define_field(:double, :transaction_price_facet, :stored => true) do
      get_transaction_price
    end

    #### Details

    define_field(:text, :title, :stored => true) do
      entry_titles.map &:title
    end
    define_field(:string, :title_facet,:stored => true, :multiple => true) do
      entry_titles.map &:title
    end

    define_field(:text, :author, :stored => true) do
      authors.map &:name
    end
    define_field(:string, :author_facet, :stored => true, :multiple => true) do
      authors.map &:name
    end

    # TODO: fiddle with this for a better facet taking into account circa
    define_field(:integer, :manuscript_date_facet, :stored => true, :multiple => true) do
      entry_dates.map &:date
    end

    define_field(:string, :artist_facet, :stored => true, :multiple => true) do
      artists.map &:name
    end

    define_field(:string, :scribe_facet, :stored => true, :multiple => true) do
      scribes.map &:name
    end

    define_field(:string, :language_facet, :stored => true, :multiple => true) do
      languages.map &:name
    end

    define_field(:string, :material_facet, :stored => true, :multiple => true) do
      entry_materials.map &:material
    end

    define_field(:string, :place_facet, :stored => true, :multiple => true) do
      places.map &:name
    end

    define_field(:string, :use_facet, :stored => true, :multiple => true) do
      entry_uses.map &:use
    end

    define_field(:integer, :folios_facet, :stored => true) { folios }
    define_field(:integer, :num_columns_facet, :stored => true) { num_columns }
    define_field(:integer, :num_lines_facet, :stored => true) { num_lines }
    define_field(:integer, :height_facet, :stored => true) { height }
    define_field(:integer, :width_facet, :stored => true) { width }
    define_field(:integer, :miniatures_fullpage_facet, :stored => true) { miniatures_fullpage }
    define_field(:integer, :miniatures_large_facet, :stored => true) { miniatures_large }
    define_field(:integer, :miniatures_small_facet, :stored => true) { miniatures_small }
    define_field(:integer, :miniatures_unspec_size_facet, :stored => true) { miniatures_unspec_size }
    define_field(:integer, :initials_historiated_facet, :stored => true) { initials_historiated }
    define_field(:integer, :initials_decorated_facet, :stored => true) { initials_decorated }

    #### Provenance

    define_field(:string, :provenance_facet, :stored => true, :multiple => true) do
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

    define_field(:text, :comment, :stored => true) do
      entry_comments.select(&:public).map(&:comment).join("\n")
    end

  end

end
