class EntryArtist < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

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
    ["Rela", "Related"]
  ]

  belongs_to :entry
  belongs_to :artist, class_name: 'Name', counter_cache: :artists_count

  validates_presence_of :entry

  validate do |entry_artist|
    if !(entry_artist.artist.present? || entry_artist.observed_name.present?)
      errors[:base] << "EntryArtist objects must have either Name association or observed_name value"
    end
  end

  after_save do |entry_artist|
    if entry_artist.artist
      entry_artist.artist.is_artist = true
      entry_artist.artist.save!
    end
  end

  # used for indexing entry_artist with entry
  def display_value
    [artist ? artist.name : nil, observed_name ? "(#{observed_name})" : nil, certainty_flags, role ? "[#{format_role}]" : nil].reject(&:blank?).join(" ")
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

  def to_fields
    {name: artist ? artist.name : nil, observed_name: observed_name}
  end

  def name_authority
    (artist ? "<a href='/names/#{artist_id}'>#{artist}</a> " : "")
  end
end
