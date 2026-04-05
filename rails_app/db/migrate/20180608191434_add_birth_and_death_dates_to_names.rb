class AddBirthAndDeathDatesToNames < ActiveRecord::Migration[4.2]
  def change
    add_column :names, :startdate, :string
    add_column :names, :enddate, :string
  end
end
