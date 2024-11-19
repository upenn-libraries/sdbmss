class CreateProvenance < ActiveRecord::Migration
  def change
    create_table :provenance do |t|
      t.references :entry, index: true
      t.integer  :order
      t.string   :observed_name
      t.references :provenance_agent, index: true
      t.string   :acquisition_method
      t.boolean  :direct_transfer, default: false
      t.datetime :created_at
      t.integer  :created_by_id
      t.datetime :updated_at
      t.integer  :updated_by_id
      t.string   :start_date
      t.string   :start_date_normalized_start
      t.string   :start_date_normalized_end
      t.string   :end_date
      t.string   :end_date_normalized_start
      t.string   :end_date_normalized_end
      t.text     :comment
      t.boolean  :uncertain_in_source, default: false
      t.boolean  :supplied_by_data_entry, default: false
    end

    add_foreign_key :provenance, :names, column: :provenance_agent_id
  end
end
