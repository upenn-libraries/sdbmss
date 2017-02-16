class DericciGame < ActiveRecord::Base
  has_many :dericci_game_records, dependent: :destroy
  has_many :dericci_records, through: :dericci_game_records
  has_many :dericci_links, through: :dericci_records

  accepts_nested_attributes_for :dericci_links, allow_destroy: true
  accepts_nested_attributes_for :dericci_records

  belongs_to :created_by, class_name: 'User'
end