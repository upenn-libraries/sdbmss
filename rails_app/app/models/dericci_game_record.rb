class DericciGameRecord < ActiveRecord::Base
  belongs_to :dericci_game
  belongs_to :dericci_record
end