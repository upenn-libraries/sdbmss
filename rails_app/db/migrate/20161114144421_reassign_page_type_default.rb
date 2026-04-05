class ReassignPageTypeDefault < ActiveRecord::Migration[4.2]
  def change
    change_column :pages, :type, :string, default: 'upload'
  end
end
