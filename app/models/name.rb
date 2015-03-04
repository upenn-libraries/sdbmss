
# This is the place where all the names of people and institutions,
# associated with Entries in various ways, are stored.
class Name < ActiveRecord::Base

  default_scope { where(deleted: false) }

  belongs_to :entry

  belongs_to :approved_by, :class_name => 'User'

  include UserFields

  has_many :entry_artists, foreign_key: "artist_id"

  has_many :entry_authors, foreign_key: "author_id"

  has_many :entry_scribes, foreign_key: "scribes_id"

  has_many :event_agents, foreign_key: "agent_id"
  has_many :events, through: :event_agents

  has_many :source_agents, foreign_key: "agent_id"
  has_many :sources, through: :source_agents

  validates_presence_of :name

  validate do |name_obj|
    if !(name_obj.is_artist || name_obj.is_author || name_obj.is_scribe || name_obj.is_provenance_agent)
      errors[:base] << "Name objects must have at least one flag set"
    end
  end

  # constructor for a Provenance Agent
  def self.agent
    new(is_provenance_agent: true)
  end

  # constructor for an Artist
  def self.artist
    new(is_artist: true)
  end

  # constructor for an Author
  def self.author
    new(is_author: true)
  end

  # constructor for a Scribe
  def self.scribe
    new(is_scribe: true)
  end

  # This find_or_create constructor looks for a name, creating it if
  # necessary, while also flagging it as is_artist, is_author, etc
  # according to passed in 'flag' arg, which should be a symbol.
  def self.find_or_create_by_flag(name, flag)
    obj = where(name: name).first
    if obj
      if !obj.send(flag)
        obj.send("#{flag}=", true)
        obj.save!
      end
    else
      attrs = {
        name: name,
      }
      attrs[flag] = true
      obj = create!(attrs)
    end
    obj
  end

  def self.find_or_create_agent(name)
    find_or_create_by_flag(name, :is_provenance_agent)
  end

  def self.find_or_create_artist(name)
    find_or_create_by_flag(name, :is_artist)
  end

  def self.find_or_create_author(name)
    find_or_create_by_flag(name, :is_author)
  end

  def self.find_or_create_scribe(name)
    find_or_create_by_flag(name, :is_scribe)
  end

  def public_id
    "SDBM_NAME_#{id}"
  end

  def to_s
    name
  end

end
