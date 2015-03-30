class CreateSourceTypes < ActiveRecord::Migration
  def change
    create_table :source_types do |t|
      t.string :name
      t.string :display_name
      t.string :entries_transaction_field
      t.boolean :entries_have_institution_field
    end
  end
end
