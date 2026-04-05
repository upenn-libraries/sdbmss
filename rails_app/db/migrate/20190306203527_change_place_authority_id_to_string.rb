class ChangePlaceAuthorityIdToString < ActiveRecord::Migration[4.2]
  def change
  	change_column :places, :authority_id, :string
  end
end
