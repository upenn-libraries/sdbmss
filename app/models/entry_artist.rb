class EntryArtist < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

  include TellBunny

  TYPES_ROLES = [
    ["Work", "Workshop"], 
    ["Styl", "Style"], 
    ["Circ", "Circle"], 
    ["Scho", "School"], 
    ["Asso", "Associate"], 
    ["Assos", "Associates"], 
    ["Atel", "Atelier"], 
    ["Arti", "Artist"], 
    ["Grou", "Group"], 
    ["Styls", "Styles"], 
    ["Foll", "Follower"], 
    ["Desc", "Descendant"], 
    ["Folls", "Followers"], 
    ["Cont", "Contemporary"], 
    ["Son", "Son"], 
    ["Mann", "Manner"], 
    ["Mini", "Miniatures"], 
    ["Prov", "Provincial"], 
    ["Pupi", "Pupil"], 
    ["Coll", "Collaborators"],
    ["Mast", "Master"],
    ["Assi", "Assistant"],
    ["Rela", "Related"],
    ["Attr", "Attributed"]
  ]

  belongs_to :entry
  belongs_to :artist, class_name: 'Name', counter_cache: :artists_count
  validates_length_of :observed_name, :minimum => 0, :maximum => 255, :allow_blank => true

  validates_presence_of :entry

  validate do |entry_artist|
    if !(entry_artist.artist.present? || entry_artist.observed_name.present?)
      errors[:base] << "EntryArtist objects must have either Name association or observed_name value"
    end
  end

  after_save do |entry_artist|
    if entry_artist.artist && !entry_artist.artist.is_artist
      entry_artist.artist.is_artist = true
      entry_artist.artist.save!
    end
  end

  # used for indexing entry_artist with entry
  def display_value
    [artist ? artist.name : nil, observed_name.present? ? "(#{observed_name})" : nil, role ? "[#{format_role}]" : nil].reject(&:blank?).join(" ").html_safe
  end

  def facet_value
    artist ? artist.name : nil
  end

  def format_role
    if (found = TYPES_ROLES.select{ |r| r[0] == role })
      found.first[1]
    else
      role
    end
  end

  def to_s
    (artist ? artist.name : "") + certainty_flags
  end

  def to_rdf
    {
      model_class: "entry_artists",
      id: id,
      fields: {
        observed_name: "'#{observed_name}'",
        artist_id: "<https://sdbm.library.upenn.edu/names/#{artist_id}>",
        entry_id: "<https://sdbm.library.upenn.edu/entries/#{entry_id}>",
        role: "'#{role}'",
        order: "'#{order}'^^xsd:integer",
        supplied_by_data_entry: "'#{supplied_by_data_entry}'^^xsd:boolean",
        uncertain_in_source: "'#{uncertain_in_source}'^^xsd:boolean"
      }
    }
=begin
    %Q(
      sdbm:entry_artists/#{id}
      a       sdbm:entry_artists
      sdbm:entry_artists_id #{id}
      sdbm:entry_artists_observed_name '#{observed_name}'
      sdbm:entry_artists_artist_id <https://sdbm.library.upenn.edu/names/#{artist_id}>
      sdbm:entry_artists_entry_id <https://sdbm.library.upenn.edu/entries/#{entry_id}>
      sdbm:entry_artists_role '#{role}'
      sdbm:entry_artists_order #{order}
      sdbm:entry_artists_supplied_by_data_entry '#{supplied_by_data_entry}'^^xsd:boolean
      sdbm:entry_artists_uncertain_in_source '#{uncertain_in_source}'^^xsd:boolean
    )
=end
  end

end