class RenameDericciLinkTable < ActiveRecord::Migration[4.2]
  def change
    rename_table :dericci_link, :dericci_links
  end
end
