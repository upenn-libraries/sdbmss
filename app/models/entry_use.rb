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

    map[:fields][:use]      = format_triple_object use,      :string
    map[:fields][:entry_id] = format_triple_object entry_id, :uri,    'https://sdbm.library.upenn.edu/entries/'
    map[:fields][:order]    = format_triple_object order,    :integer

    map
  end

end
