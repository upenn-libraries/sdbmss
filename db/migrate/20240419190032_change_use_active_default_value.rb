class ChangeUseActiveDefaultValue < ActiveRecord::Migration
  def up
    change_column_default :users, :active, false
  end

  def down
    change_column_default :users, :active, true
    end
end
