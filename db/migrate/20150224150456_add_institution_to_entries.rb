class AddInstitutionToEntries < ActiveRecord::Migration
  def change
    add_column :entries, :institution_id, :integer, references: :agents
    add_index :entries, :institution_id
  end
end
