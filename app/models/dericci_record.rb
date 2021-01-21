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

    map[:fields][:dates]        = format_triple_object dates,        :string
    map[:fields][:name]         = format_triple_object name,         :string
    map[:fields][:place]        = format_triple_object place,        :string
    map[:fields][:url]          = format_triple_object url,          :string
    map[:fields][:cards]        = format_triple_object cards,        :integer
    map[:fields][:size]         = format_triple_object size,         :string
    map[:fields][:other_info]   = format_triple_object other_info,   :string
    map[:fields][:senate_house] = format_triple_object senate_house, :string
    map[:fields][:out_of_scope] = format_triple_object out_of_scope, :boolean

    map
  end

end