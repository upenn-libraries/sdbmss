class ChangeManuscriptBindingInEntries < ActiveRecord::Migration[4.2]
  def change
    change_column :entries, :manuscript_binding, :string, :limit => 1024
  end
end
