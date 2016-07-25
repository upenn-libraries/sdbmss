class AddUserToDownloads < ActiveRecord::Migration
  def change
    add_reference :downloads, :user, index: true
  end
end
