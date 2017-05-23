class DericciRecord < ActiveRecord::Base
  has_many :dericci_links
  has_many :names, through: :dericci_links

  has_many :dericci_record_flags

  belongs_to :verified, class_name: "Name"

  has_many :bookmarks, as: :document, dependent: :destroy
  has_many :comments, as: :commentable
 
  include Watchable 
  include UserFields

  accepts_nested_attributes_for :dericci_links, allow_destroy: true
  accepts_nested_attributes_for :dericci_record_flags, allow_destroy: true
  accepts_nested_attributes_for :comments

  def public_id
    "De Ricci #{id}"
  end

  def bookmark_details
    results = {
      name: name,
      size: size,
      cards: cards,
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