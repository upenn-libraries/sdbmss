class Entry < ActiveRecord::Base
  belongs_to :source
  belongs_to :added_by, class_name: 'User'
  belongs_to :last_modified_by, class_name: 'User'

  has_many :entry_manuscripts
  has_many :manuscripts, through: :entry_manuscripts
  has_many :entry_titles
  has_many :entry_authors
  has_many :entry_dates
  has_many :entry_artists
  has_many :entry_scribes
  has_many :entry_languages
  has_many :entry_materials
  has_many :entry_places
  has_many :entry_uses
  has_many :entry_comments
  has_many :events

  # aggressively load all associations; useful for cases when you need to display complete info for the Entry
  # TODO: fill this out
  scope :load_associations, -> { includes(:entry_authors, :entry_dates, :entry_titles, :entry_places => [:place], :events => [{:event_agents => [:agent]} ], :source => [{:source_agents => [:agent]}]) }

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
  
  # for sunspot. these field names do NOT get defined in Solr's
  # schema.xml. instead, they get appended with suffixes like '_is'
  # and '_ss', which the generic schema.xml has been configured to
  # recognize as dynamic fields. I'm not sure of the implications of
  # doing it this way (or whether sunspot even supports 'normal'
  # non-dynamic fields), just going with the flow for now.
  #
  # NOTE ABOUT FIELD TYPES:
  #
  # :text gets tokenized, :string does NOT. sometimes (often?) we need
  # two fields for the same piece of data, to support both faceting
  # and keyword searches.
  #
  #  TODO: set auto_index to false to prevent migration script from
  #  indexing, but we want it to be ON for normal operation. how to do
  #  this?
  searchable :auto_index => false do
    # complete_entry is for general full-text search, so dump
    # everything here
    text :complete_entry, :stored => true do
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
        entry_titles.map { |obj| obj.title },
        entry_authors.map { |obj| obj.author ? obj.author.name : nil },
        entry_dates.map { |obj| obj.date },
        entry_dates.map { |obj| obj.get_display_value },
        entry_artists.map { |obj| obj.artist.name },
        entry_scribes.map { |obj| obj.scribe.name },
        entry_languages.map { |obj| obj.language.name },
        entry_materials.map { |obj| obj.material },
        entry_places.map { |obj| obj.place.name },
        entry_uses.map { |obj| obj.use },
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

    # for display
    string :sdbm_id, :stored => true do
      "SBDM_" + @__receiver__.id.to_s
    end

    # for sorting
    integer :entry_id, :stored => true do
      @__receiver__.id.to_i
    end

    integer :manuscripts, :stored => true, :multiple => true do
      entry_manuscripts.map { |em| em.manuscript.id }
    end

    #### Source info

    # this one's for keyword searching
    text :source, :stored => true do
      source.get_display_value
    end
    # this one's for faceting
    string :source, :stored => true do
      source.get_display_value
    end
    text :source_date, :stored => true do
      source.date
    end

    string :catalog_or_lot_number, :stored => true
    string :secondary_source, :stored => true
    string :current_location, :stored => true

    #### Transaction info

    string :transaction_seller_agent, :stored => true do
      get_transaction_seller_agent_name
    end

    string :transaction_seller, :stored => true do
      get_transaction_seller_or_holder_name
    end

    string :transaction_buyer, :stored => true do
      get_transaction_buyer_name
    end

    string :transaction_sold, :stored => true do
      get_transaction_sold
    end

    double :transaction_price, :stored => true do
      get_transaction_price
    end

    #### Details

    text :title, :stored => true do
      entry_titles.map { |obj| obj.title }
    end
    string :title, :stored => true, :multiple => true do
      entry_titles.map { |obj| obj.title }
    end

    text :author, :stored => true do
      entry_authors.map { |obj| obj.author ? obj.author.name : nil }
    end
    string :author, :stored => true, :multiple => true do
      entry_authors.map { |obj| obj.author ? obj.author.name : nil }
    end

    # TODO: fiddle with this for a better facet taking into account circa
    integer :manuscript_date, :stored => true, :multiple => true do
      entry_dates.map { |obj| obj.date }
    end

    # this one's for display
    string :manuscript_date_display, :stored => true, :multiple => true do
      entry_dates.map { |obj| obj.get_display_value }
    end

    string :artist, :stored => true, :multiple => true do
      entry_artists.map { |obj| obj.artist.name }
    end

    string :scribe, :stored => true, :multiple => true do
      entry_scribes.map { |obj| obj.scribe.name }
    end

    string :language, :stored => true, :multiple => true do
      entry_languages.map { |obj| obj.language.name }
    end

    string :material, :stored => true, :multiple => true do
      entry_materials.map { |obj| obj.material }
    end

    string :place, :stored => true, :multiple => true do
      entry_places.map { |obj| obj.place.name }
    end

    string :use, :stored => true, :multiple => true do
      entry_uses.map { |obj| obj.use }
    end

    integer :folios, :stored => true
    integer :num_columns, :stored => true
    integer :num_lines, :stored => true
    integer :height, :stored => true
    integer :width, :stored => true
    string :alt_size, :stored => true
    string :manuscript_binding, :stored => true
    string :other_info, :stored => true
    string :manuscript_link, :stored => true
    integer :miniatures_fullpage, :stored => true
    integer :miniatures_large, :stored => true
    integer :miniatures_small, :stored => true
    integer :miniatures_unspec_size, :stored => true
    integer :initials_historiated, :stored => true
    integer :initials_decorated, :stored => true

    #### Provenance

    string :provenance, :stored => true, :multiple => true do
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

    string :comment, :stored => true, :multiple => true do
      entry_comments.select { |ec| ec.public }.map { |ec| ec.comment }
    end

  end

end
