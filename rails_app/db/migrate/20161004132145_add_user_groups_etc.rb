class AddUserGroupsEtc < ActiveRecord::Migration
  def change
    create_table :groups do |t|
      t.text :name
      t.boolean :public, default: false
      t.integer :created_by, foreign_key: true
      t.integer :updated_by, foreign_key: true

      t.timestamps null: false
    end

    create_table :group_users do |t|
      t.integer :group_id
      t.integer :user_id
    end

    create_table :group_records do |t|
      t.integer :record_id
      t.string :record_type
      t.integer :group_id
    end
  end
end
