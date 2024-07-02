class RenameEventsToSales < ActiveRecord::Migration
  def change

    create_table "sales", force: :cascade do |t|
      t.integer  "entry_id",                    limit: 4
      t.string   "date",                    limit: 255
      t.decimal  "price",                                     precision: 20, scale: 2
      t.string   "currency",                    limit: 255
      t.string   "other_currency",              limit: 255
      t.string   "sold",                        limit: 255
      t.datetime "created_at"
      t.integer  "created_by_id",               limit: 4
      t.datetime "updated_at"
      t.integer  "updated_by_id",               limit: 4
    end

    add_index :sales, :created_by_id
    add_index :sales, :entry_id
    add_index :sales, :updated_by_id

    create_table "sale_agents", force: :cascade do |t|
      t.integer  "sale_id",               limit: 4
      t.string   "observed_name",          limit: 255
      t.integer  "agent_id",               limit: 4
      t.string   "role",                   limit: 255
      t.datetime "created_at"
      t.datetime "updated_at"
      t.boolean  "uncertain_in_source",                default: false
      t.boolean  "supplied_by_data_entry",             default: false
    end

    add_index :sale_agents, :agent_id
    add_index :sale_agents, :sale_id
    add_index :sale_agents, :observed_name

    add_foreign_key :sale_agents, :sales, on_delete: :cascade
    add_foreign_key :sale_agents, :names, column: :agent_id
    add_foreign_key :sales, :entries, on_delete: :cascade
    add_foreign_key :sales, :users, column: :created_by_id
    add_foreign_key :sales, :users, column: :updated_by_id

    drop_table :event_agents
    drop_table :events
  end
end
