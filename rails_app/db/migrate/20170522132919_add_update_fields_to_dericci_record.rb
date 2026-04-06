class AddUpdateFieldsToDericciRecord < ActiveRecord::Migration[4.2]
  def change    
    add_reference :dericci_records, :updated_by, :index => true
  end
end
