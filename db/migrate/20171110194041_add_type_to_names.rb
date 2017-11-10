class AddTypeToNames < ActiveRecord::Migration
  def change
    add_column :names, :type, :string
  end
end
