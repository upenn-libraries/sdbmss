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
    %Q(
      sdbm:dericci_records/#{id}
      a       sdbm:dericci_records
      sdbm:dericci_records_id #{id}
      sdbm:dericci_records_dates '#{dates}'
      sdbm:dericci_records_name '#{name}'
      sdbm:dericci_records_place '#{place}'
      sdbm:dericci_records_url '#{url}'
      sdbm:dericci_records_cards #{cards}
      sdbm:dericci_records_size '#{size}'
      sdbm:dericci_records_other_info '#{other_info}'
      sdbm:dericci_records_senate_house '#{senate_house}'
      sdbm:dericci_records_out_of_scope '#{out_of_scope}'^^xsd:boolean
    )
    #  rdfs:label "dericci_links #1" ;
    
  end

end