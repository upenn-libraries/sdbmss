class ChangeThreddedTableEngines < ActiveRecord::Migration
  def change
    change_table :thredded_categories, :options => "ENGINE=MyISAM" do      
    end

    change_table :thredded_posts, :options => "ENGINE=MyISAM" do      
    end

    change_table :thredded_topics, :options => "ENGINE=MyISAM" do      
    end
  end
end
