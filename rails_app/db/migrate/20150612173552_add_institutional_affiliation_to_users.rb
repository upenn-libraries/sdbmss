class AddInstitutionalAffiliationToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :institutional_affiliation, :string
  end
end
