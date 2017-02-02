class DericciLink < ActiveRecord::Base
  belongs_to :name
  belongs_to :dericci_record

  validates_uniqueness_of :name_id, :scope => :dericci_record_id
end