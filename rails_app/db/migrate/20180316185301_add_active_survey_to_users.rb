class AddActiveSurveyToUsers < ActiveRecord::Migration[4.2]
  def change
    add_column :users, :active_survey, :boolean, :default => true
  end
end
