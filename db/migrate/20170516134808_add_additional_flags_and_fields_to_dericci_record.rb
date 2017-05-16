class AddAdditionalFlagsAndFieldsToDericciRecord < ActiveRecord::Migration
  def change
    add_reference :dericci_records, :created_by, :index => true
  end
end
