class EntryAuthor < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName

  belongs_to :entry
  belongs_to :author, class_name: 'Name', counter_cache: :authors_count

  validates_presence_of :entry

  validate do |entry_author|
    if !(entry_author.author.present? || entry_author.observed_name.present?)
      errors[:base] << "EntryAuthor objects must have either Name association or observed_name value"
    end
  end

  has_paper_trail skip: [:created_at, :updated_at]

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

  def display_value
    val = super(author)
    val += role ? " (" + role + ")": ""
  end

end
