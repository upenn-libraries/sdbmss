class AddProvenanceCountToNames < ActiveRecord::Migration[4.2]
  def change
    add_column :names, :provenance_count, :integer, :default => 0, :null => false
  end
end
