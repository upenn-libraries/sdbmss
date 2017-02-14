class DericciGame < ActiveRecord::Base
  has_many :dericci_game_records, dependent: :destroy
  has_many :dericci_records, through: :dericci_game_records
  belongs_to :created_by, class_name: 'User'
end