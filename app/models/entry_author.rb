class EntryAuthor < ActiveRecord::Base

  include CertaintyFlags
  include DisplayableName

  belongs_to :entry
  belongs_to :author, class_name: 'Name', counter_cache: :authors_count

  validates_presence_of :entry

  TYPES_ROLES = [
    ['Attr', 'Attr'],
    ['Tr', 'Tr'],
    ['Com', 'Com'],
    ['Comp', 'Comp'],
    ['Ed', 'Ed'],
    ['Gl', 'Gl'],
    ['Pref', 'Pref'],
    ['Intr', 'Intr']
  ]

  def display_value
    val = super(author)
    val += role ? " (" + role + ")": ""
  end

end
