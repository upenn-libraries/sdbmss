class AddTypeAndDateToDownload < ActiveRecord::Migration
  def change
    add_reference :downloads, :created_by, :index => true
  end
end
