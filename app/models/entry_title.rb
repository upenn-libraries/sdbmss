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
    map = {
      model_class: "entry_titles",
      id: id,
      fields: {}
    }

    map[:fields][:title]                  = format_triple_object title,                  :string
    map[:fields][:common_title]           = format_triple_object common_title,           :string
    map[:fields][:entry_id]               = format_triple_object entry_id,               :uri,            'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:order]                  = format_triple_object order,                  :integer
    map[:fields][:supplied_by_data_entry] = format_triple_object supplied_by_data_entry, :boolean
    map[:fields][:uncertain_in_source]    = format_triple_object uncertain_in_source,    :boolean

    map
  end

end
