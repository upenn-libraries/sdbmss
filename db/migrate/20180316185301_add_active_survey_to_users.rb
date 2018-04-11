class AddActiveSurveyToUsers < ActiveRecord::Migration
  def change
    add_column :users, :active_survey, :boolean, :default => true
  end
end
