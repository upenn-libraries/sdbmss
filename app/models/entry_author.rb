class EntryAuthor < ActiveRecord::Base
  belongs_to :entry
  belongs_to :author

  def get_display_value
    case
    when author && observed_name
      "#{author.name} #{observed_name}"
    when author
      "#{author.name}"
    when observed_name
      "#{observed_name}"
    end
  end

end
