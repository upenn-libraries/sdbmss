class AddTypeToNames < ActiveRecord::Migration[4.2]
  def change
    add_column :names, :type, :string
  end
end
