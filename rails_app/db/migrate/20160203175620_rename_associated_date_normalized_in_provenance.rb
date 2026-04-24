class RenameAssociatedDateNormalizedInProvenance < ActiveRecord::Migration[4.2]
  def change
    change_table :provenance do |t|
      t.rename :associated_date_start, :associated_date_normalized_start
      t.rename :associated_date_end, :associated_date_normalized_end
    end
  end
end
