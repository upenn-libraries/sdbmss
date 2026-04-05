class AddUserToDownloads < ActiveRecord::Migration[4.2]
  def change
    add_reference :downloads, :user, index: true
  end
end
