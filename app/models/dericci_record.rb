class DericciRecord < ActiveRecord::Base
  has_many :dericci_links
  has_many :names, through: :dericci_links

  accepts_nested_attributes_for :dericci_links, allow_destroy: true

  def public_id
    "De Ricci #{id}"
  end

  def bookmark_details
    results = {
      name: name,
      size: size,
      url: url,
      cards: cards,
      place: place,
      dates: dates
    }
    (results.select { |k, v| !v.blank? }).transform_keys{ |key| key.to_s.humanize }
  end

  def to_s
    name
  end

  def preview
    name
  end

end