class AddPageFileModel < ActiveRecord::Migration
  def change
    create_table :pages do |t|
      t.string :filename
    end
  end
end
