class EntryAuthor < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :author, class_name: 'Name'

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
    case
    when author && observed_name
      "#{author.name} (#{observed_name})" + (role ? " (" + role + ")": "")
    when author
      "#{author.name}" + (role ? " (" + role + ")" : "")
    when observed_name
      "#{observed_name}" + (role ? " (" + role + ")" : "")
    end
  end

end
