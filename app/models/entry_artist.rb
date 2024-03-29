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
    map = {
      model_class: "entry_artists",
      id: id,
      fields: {}
    }

    map[:fields][:observed_name]          = format_triple_object observed_name,          :string
    map[:fields][:artist_id]              = format_triple_object artist_id,              :uri,            'https://sdbm.library.upenn.edu/names/'
    map[:fields][:entry_id]               = format_triple_object entry_id,               :uri,            'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:role]                   = format_triple_object role,                   :string
    map[:fields][:order]                  = format_triple_object order,                  :integer
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end

end