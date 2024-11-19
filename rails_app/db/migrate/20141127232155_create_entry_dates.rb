class CreateEntryDates < ActiveRecord::Migration
  def change
    create_table :entry_dates do |t|
      t.references :entry, index: true
      t.string :date
      t.string :circa

    end
  end
end
