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

    map[:fields][:title]                  = "'''#{title.to_s.gsub("'", "")}'''"                    if title.present?
    map[:fields][:common_title]           = "'''#{common_title.to_s.gsub("'", "")}'''"             if common_title.present?
    map[:fields][:entry_id]               = "<https://sdbm.library.upenn.edu/entries/#{entry_id}>" if entry_id.present?
    map[:fields][:order]                  = "'#{order}'^^xsd:integer"                              if order.present?
    map[:fields][:supplied_by_data_entry] = "'#{supplied_by_data_entry}'^^xsd:boolean"             unless supplied_by_data_entry.nil?
    map[:fields][:uncertain_in_source]    = "'#{uncertain_in_source}'^^xsd:boolean"                unless uncertain_in_source.nil?

    map
  end

end
