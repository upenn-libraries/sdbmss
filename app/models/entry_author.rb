class EntryAuthor < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName
  include HasPaperTrail

  include TellBunny

  TYPES_ROLES = [
    ['Attr', 'Attributed'],
    ['Tr', 'Translator'],
    ['Com', 'Commentator'],
    ['Comp', 'Compiler'],
    ['Ed', 'Editor'],
    ['Gl', 'Glossator'],
    ['Pref', 'Preface'],
    ['Intr', 'Introduction']
  ]

  belongs_to :entry
  belongs_to :author, class_name: 'Name', counter_cache: :authors_count

  validates_presence_of :entry
  validates_inclusion_of :role, in: TYPES_ROLES.map(&:first), allow_nil: true
  validates_length_of :observed_name, :minimum => 0, :maximum => 255, :allow_blank => true

  validate do |entry_author|
    if !(entry_author.author.present? || entry_author.observed_name.present?)
      errors[:base] << "EntryAuthor objects must have either Name association or observed_name value"
    end
  end

  after_save do |entry_author|
    if entry_author.author && !entry_author.author.is_author
      entry_author.author.is_author = true
      entry_author.author.save!
    end
  end

  # used for indexing entry_artist with entry
  def display_value
    [author ? author.name : nil, observed_name.present? ? "(#{observed_name})" : nil, role ? "[#{role.humanize}]" : nil].reject(&:blank?).join(" ")
  end

  def facet_value
    author ? author.name : nil
  end

  def to_rdf
    map = {
      model_class: "entry_authors",
      id: id,
      fields: {}
    }

    map[:fields][:observed_name]          = format_triple_object observed_name,          :string_to_clean
    map[:fields][:author_id]              = format_triple_object author_id,              :uri,            'https://sdbm.library.upenn.edu/names/'
    map[:fields][:entry_id]               = format_triple_object entry_id,               :uri,            'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:role]                   = format_triple_object role,                   :string
    map[:fields][:order]                  = format_triple_object order,                  :integer
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end

end
