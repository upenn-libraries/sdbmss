class EntryUse < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry
  validates_presence_of :use
  validates_length_of :use, :minimum => 0, :maximum => 255, :allow_blank => true

  include HasPaperTrail
  include TellBunny

  def to_rdf
    map = {
      model_class: "entry_uses",
      id: id,
      fields: {}
    }

    map[:fields][:use]      = "'''#{rdf_string_prep use}'''"                         if use.present?
    map[:fields][:entry_id] = "<https://sdbm.library.upenn.edu/entries/#{entry_id}>" if entry_id.present?
    map[:fields][:order]    = "'#{order}'^^xsd:integer"                              if order.present?

    map
  end

end
