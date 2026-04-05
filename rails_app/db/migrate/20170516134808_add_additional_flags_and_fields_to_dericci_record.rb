class AddAdditionalFlagsAndFieldsToDericciRecord < ActiveRecord::Migration[4.2]
  def change
    add_reference :dericci_records, :created_by, :index => true
  end
end
