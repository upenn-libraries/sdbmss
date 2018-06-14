class NamePlace < ActiveRecord::Base

  include TellBunny

  belongs_to :name
  belongs_to :place

  validates_presence_of :place

  def display_value (mode)
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
    %Q(
      sdbm:name_places/#{id}
      a       sdbm:name_places
      sdbm:name_places_id #{id}
      sdbm:name_places_place_id <https://sdbm.library.upenn.edu/places/#{place_id}>
      sdbm:name_places_name_id <https://sdbm.library.upenn.edu/names/#{name_id}>
      sdbm:name_places_notbefore #{notbefore}
      sdbm:name_places_notafter #{notafter}
    )
  end

end