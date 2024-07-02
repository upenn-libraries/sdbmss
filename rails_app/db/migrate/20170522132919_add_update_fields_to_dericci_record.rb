class AddUpdateFieldsToDericciRecord < ActiveRecord::Migration
  def change    
    add_reference :dericci_records, :updated_by, :index => true
  end
end
