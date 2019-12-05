class DericciRecord < ActiveRecord::Base
  has_many :dericci_links
  has_many :names, through: :dericci_links

  has_many :dericci_record_flags

  belongs_to :verified, class_name: "Name"

  has_many :bookmarks, as: :document, dependent: :destroy
  has_many :comments, as: :commentable
 
  include Watchable 
  include UserFields
  include TellBunny

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
      url: url,
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

  def to_rdf
    map = {
      model_class: "dericci_records",
      id: id,
      fields: {}
    }

    map[:fields][:dates]        = "'''#{dates}'''"                 if dates.present?
    map[:fields][:name]         = "'''#{name}'''"                  if name.present?
    map[:fields][:place]        = "'''#{place}'''"                 if place.present?
    map[:fields][:url]          = "'''#{url}'''"                   if url.present?
    map[:fields][:cards]        = "'#{cards}'^^xsd:integer"        if cards.present?
    map[:fields][:size]         = "'''#{size}'''"                  if size.present?
    map[:fields][:other_info]   = "'''#{other_info}'''"            if other_info.present?
    map[:fields][:senate_house] = "'''#{senate_house}'''"          if senate_house.present?
    map[:fields][:out_of_scope] = "'#{out_of_scope}'^^xsd:boolean" unless out_of_scope.nil?

    map
  end

end