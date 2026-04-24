class AddLinkToDericciNote < ActiveRecord::Migration[4.2]
  def change
    add_column :dericci_notes, :link, :string
  end
end
