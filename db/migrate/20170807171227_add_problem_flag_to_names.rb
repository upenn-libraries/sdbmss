class AddProblemFlagToNames < ActiveRecord::Migration
  def change
    add_column :names, :problem, :boolean, :default => false
  end
end
