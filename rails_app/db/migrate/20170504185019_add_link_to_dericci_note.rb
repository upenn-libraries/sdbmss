class AddLinkToDericciNote < ActiveRecord::Migration
  def change
    add_column :dericci_notes, :link, :string
  end
end
