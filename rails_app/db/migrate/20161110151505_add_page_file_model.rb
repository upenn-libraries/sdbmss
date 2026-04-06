class AddPageFileModel < ActiveRecord::Migration[4.2]
  def change
    create_table :pages do |t|
      t.string :filename
    end
  end
end
