class AddBirthAndDeathDatesToNames < ActiveRecord::Migration
  def change
    add_column :names, :startdate, :string
    add_column :names, :enddate, :string
  end
end
