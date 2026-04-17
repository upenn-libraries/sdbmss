class AddProblemFlagToNames < ActiveRecord::Migration[4.2]
  def change
    add_column :names, :problem, :boolean, :default => false
  end
end
