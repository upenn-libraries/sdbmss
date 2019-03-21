class EntryUse < ActiveRecord::Base
  belongs_to :entry

  validates_presence_of :entry
  validates_presence_of :use
  validates_length_of :use, :minimum => 0, :maximum => 255, :allow_blank => true

  include HasPaperTrail
  include TellBunny

  def to_rdf
    {
      model_class: "entry_uses",
      id: id,
      fields: {
        use: "'''#{use}'''",
        entry_id: "<https://sdbm.library.upenn.edu/entries/#{entry_id}>",
        order: "'#{order}'^^xsd:integer"
      }
    }
=begin
    %Q(
      sdbm:entry_uses/#{id}
      a       sdbm:entry_uses
      sdbm:entry_uses_id #{id}
      sdbm:entry_uses_use '#{use}'
      sdbm:entry_uses_entry_id <https://sdbm.library.upenn.edu/entries/#{entry_id}>
      sdbm:entry_uses_order #{order}
    )
=end
  end

end
