class AddInstitutionalAffiliationToUsers < ActiveRecord::Migration
  def change
    add_column :users, :institutional_affiliation, :string
  end
end
