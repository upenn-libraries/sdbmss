class ChangeManuscriptBindingInEntries < ActiveRecord::Migration
  def change
    change_column :entries, :manuscript_binding, :string, :limit => 1024
  end
end
