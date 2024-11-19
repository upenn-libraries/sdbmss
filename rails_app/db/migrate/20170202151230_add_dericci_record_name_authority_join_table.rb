class AddDericciRecordNameAuthorityJoinTable < ActiveRecord::Migration
  def change
    create_table :dericci_link do |t|
      t.integer :name_id
      t.integer :dericci_record_id
    end
  end
end
