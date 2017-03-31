class RenameDericciLinkTable < ActiveRecord::Migration
  def change
    rename_table :dericci_link, :dericci_links
  end
end
