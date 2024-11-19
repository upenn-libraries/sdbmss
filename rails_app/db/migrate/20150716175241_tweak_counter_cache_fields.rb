class TweakCounterCacheFields < ActiveRecord::Migration
  def change
    execute "update languages set entries_count = 0 where entries_count is null;"
    change_column(:languages, :entries_count, :integer, null: false, default: 0)

    execute "update manuscripts set entries_count = 0 where entries_count is null;"
    change_column(:manuscripts, :entries_count, :integer, null: false, default: 0)

    execute "update names set authors_count = 0 where authors_count is null;"
    change_column(:names, :authors_count, :integer, null: false, default: 0)

    execute "update names set artists_count = 0 where artists_count is null;"
    change_column(:names, :artists_count, :integer, null: false, default: 0)

    execute "update names set scribes_count = 0 where scribes_count is null;"
    change_column(:names, :scribes_count, :integer, null: false, default: 0)

    execute "update names set source_agents_count = 0 where source_agents_count is null;"
    change_column(:names, :source_agents_count, :integer, null: false, default: 0)

    execute "update names set event_agents_count = 0 where event_agents_count is null;"
    change_column(:names, :event_agents_count, :integer, null: false, default: 0)

    execute "update places set entries_count = 0 where entries_count is null;"
    change_column(:places, :entries_count, :integer, null: false, default: 0)

    execute "update sources set entries_count = 0 where entries_count is null;"
    change_column(:sources, :entries_count, :integer, null: false, default: 0)
  end
end
