class DericciGame < ActiveRecord::Base

  include CreatesActivity
  include HasPaperTrail

  has_many :dericci_game_records, dependent: :destroy
  has_many :dericci_records, through: :dericci_game_records
  has_many :dericci_record_flags, through: :dericci_records
  has_many :dericci_links, through: :dericci_records

  accepts_nested_attributes_for :dericci_links, allow_destroy: true
  accepts_nested_attributes_for :dericci_record_flags, allow_destroy: true
  accepts_nested_attributes_for :dericci_records

  belongs_to :created_by, class_name: 'User'

  def create_activity(action_name, current_user, transaction_id)
    activity = Activity.new(
      item_type: "DericciGame",
      item_id: id,
      event: action_name == 'update' ? 'update' : 'play',
      user_id: current_user.id,
      transaction_id: transaction_id
    )
    success = activity.save
    if !success
      Rails.logger.error "Error saving Activity object (): #{activity.errors.messages}"
    end
    activity
  end  

end