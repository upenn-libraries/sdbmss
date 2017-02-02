class DericciRecord < ActiveRecord::Base
  has_many :dericci_links
  has_many :names, through: :dericci_links

  accepts_nested_attributes_for :dericci_links, allow_destroy: true
end