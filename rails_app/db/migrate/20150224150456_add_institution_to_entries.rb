class AddInstitutionToEntries < ActiveRecord::Migration[4.2]
  def change
    add_column :entries, :institution_id, :integer, references: :agents
    add_index :entries, :institution_id
  end
end
