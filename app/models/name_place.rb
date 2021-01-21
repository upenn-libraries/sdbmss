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
    map = {
      model_class: "name_places",
      id: id,
      fields: {}
    }

    map[:fields][:place_id]  = format_triple_object place_id,  :uri,   'https://sdbm.library.upenn.edu/places/'
    map[:fields][:name_id]   = format_triple_object name_id,   :uri,   'https://sdbm.library.upenn.edu/names/'
    map[:fields][:notbefore] = format_triple_object notbefore, :string
    map[:fields][:notafter]  = format_triple_object notafter,  :string

    map
  end

end