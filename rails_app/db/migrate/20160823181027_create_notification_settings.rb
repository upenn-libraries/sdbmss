class CreateNotificationSettings < ActiveRecord::Migration
  def change
    create_table :notification_settings do |t|
      t.integer :user_id
      t.boolean :on_update
      t.boolean :on_comment
      t.boolean :on_reply

      t.timestamps null: false
    end
  end
end
