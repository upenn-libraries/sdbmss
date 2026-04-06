class AddTypeAndDateToDownload < ActiveRecord::Migration[4.2]
  def change
    add_reference :downloads, :created_by, :index => true
  end
end
