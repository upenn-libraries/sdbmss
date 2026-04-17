class CreateNamePlaces < ActiveRecord::Migration[4.2]
  def change
   create_table :name_places do |t|
     t.references :name, index: true
     t.references :place, index: true
     t.string :notbefore
     t.string :notafter
   end
  end
end
