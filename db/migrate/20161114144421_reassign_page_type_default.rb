class ReassignPageTypeDefault < ActiveRecord::Migration
  def change
    change_column :pages, :type, :string, default: 'upload'
  end
end
