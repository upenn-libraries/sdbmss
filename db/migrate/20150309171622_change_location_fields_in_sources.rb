class ChangeLocationFieldsInSources < ActiveRecord::Migration
  def change

    # current_location => institution
    remove_column :sources, :current_location
    add_column :sources, :location_institution, :string

    # city + country => location
    remove_column :sources, :location_city
    remove_column :sources, :location_country
    add_column :sources, :location, :string

    add_column :sources, :medium, :string
    add_column :sources, :date_accessed, :string

    remove_column :sources, :cataloging_type
    remove_column :sources, :electronic_catalog_format
    remove_column :sources, :electronic_publicly_available
  end
end
