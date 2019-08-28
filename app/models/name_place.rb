class NamePlace < ActiveRecord::Base

  include TellBunny

  belongs_to :name
  belongs_to :place

  validates_presence_of :place

  def display_value (mode = 'place')
    if mode == 'name'
      val = name.name
    else
      val = place.name
    end
    if notbefore.blank? && notafter.blank?
    elsif notbefore.blank?
      val += " (before #{notafter})"
    elsif notafter.blank?
      val += " (after #{notbefore})"
    else
      val += " (#{notbefore} to #{notafter})"
    end
    val
  end

  def to_rdf
    {
      model_class: "name_places",
      id: id,
      fields: {
        place_id: "<https://sdbm.library.upenn.edu/places/#{place_id}>",
        name_id: "<https://sdbm.library.upenn.edu/names/#{name_id}>",
        notbefore: "'''#{notbefore}'''",
        notafter: "'''#{notafter}'''"
      }
    }
  end

end