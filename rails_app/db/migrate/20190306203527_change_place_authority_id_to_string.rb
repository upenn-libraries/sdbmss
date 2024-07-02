class ChangePlaceAuthorityIdToString < ActiveRecord::Migration
  def change
  	change_column :places, :authority_id, :string
  end
end
