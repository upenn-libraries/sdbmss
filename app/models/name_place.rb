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

    map[:fields][:place_id]  = "<https://sdbm.library.upenn.edu/places/#{place_id}>" if place_id.present?
    map[:fields][:name_id]   = "<https://sdbm.library.upenn.edu/names/#{name_id}>"   if name_id.present?
    map[:fields][:notbefore] = "'''#{rdf_string_prep notbefore}'''"                  if notbefore.present?
    map[:fields][:notafter]  = "'''#{rdf_string_prep notafter}'''"                   if notafter.present?

    map
  end

end