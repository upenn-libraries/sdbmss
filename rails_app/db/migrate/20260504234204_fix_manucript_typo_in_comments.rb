class FixManucriptTypoInComments < ActiveRecord::Migration[5.2]
  def up
    execute "UPDATE comments SET commentable_type = 'Manuscript' WHERE commentable_type = 'Manucript'"
  end

  def down
    raise ActiveRecord::IrreversibleMigration
  end
end
