class EntryAuthor < ActiveRecord::Base

  include CertaintyFlags

  belongs_to :entry
  belongs_to :author

  validates_presence_of :entry

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
