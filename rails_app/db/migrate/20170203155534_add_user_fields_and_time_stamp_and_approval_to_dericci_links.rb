class AddUserFieldsAndTimeStampAndApprovalToDericciLinks < ActiveRecord::Migration
  def change
    add_column(:dericci_links, :created_at, :datetime)
    add_reference(:dericci_links, :created_by, index: true)
    add_column(:dericci_links, :updated_at, :datetime)
    add_reference(:dericci_links, :updated_by, index: true)
    add_column(:dericci_links, :approved, :boolean)
  end
end
