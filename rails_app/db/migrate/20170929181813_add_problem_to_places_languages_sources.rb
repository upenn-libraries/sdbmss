class AddProblemToPlacesLanguagesSources < ActiveRecord::Migration
  def change
    add_column :places, :problem, :boolean, :default => false
    add_column :languages, :problem, :boolean, :default => false
    add_column :sources, :problem, :boolean, :default => false
  end
end
