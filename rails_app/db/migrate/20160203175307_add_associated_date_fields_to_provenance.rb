class AddAssociatedDateFieldsToProvenance < ActiveRecord::Migration
  def change
    add_column :provenance, :associated_date, :string
    add_column :provenance, :associated_date_start, :string
    add_column :provenance, :associated_date_end, :string
  end
end
