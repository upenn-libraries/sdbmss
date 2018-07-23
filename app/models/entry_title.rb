class EntryTitle < ActiveRecord::Base

  include CertaintyFlags
  include HasPaperTrail

  include TellBunny

  belongs_to :entry

  validates_presence_of :entry
  validates_length_of :title, :minimum => 0, :maximum => 255, :allow_blank => true

  def display_value
    [title, common_title ? "(#{common_title})" : nil].reject(&:blank?).join(" ").html_safe
  end

  def facet_value
    common_title ? common_title : title
  end

  def to_s
    display_value
  end

  def to_rdf
    {
      model_class: "entry_titles",
      id: id,
      fields: {
        title: "'#{title}'",
        common_title: "'#{common_title}'",
        entry_id: "<https://sdbm.library.upenn.edu/entries/#{entry_id}>",
        order: "'#{order}'^^xsd:integer",
        supplied_by_data_entry: "'#{supplied_by_data_entry}'^^xsd:boolean",
        uncertain_in_source: "'#{uncertain_in_source}'^^xsd:boolean"
      }
    }
=begin
    %Q(
      sdbm:entry_titles/#{id}
      a       sdbm:entry_titles
      sdbm:entry_titles_id #{id}
      sdbm:entry_titles_title '#{title}'
      sdbm:entry_titles_common_title '#{common_title}'
      sdbm:entry_titles_entry_id <https://sdbm.library.upenn.edu/entries/#{entry_id}>      
      sdbm:entry_titles_order #{order}
      sdbm:entry_titles_supplied_by_data_entry '#{supplied_by_data_entry}'^^xsd:boolean
      sdbm:entry_titles_uncertain_in_source '#{uncertain_in_source}'^^xsd:boolean
    )
=end
  end

end
