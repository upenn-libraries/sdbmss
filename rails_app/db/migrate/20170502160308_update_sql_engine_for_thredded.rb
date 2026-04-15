class UpdateSqlEngineForThredded < ActiveRecord::Migration[4.2]
  def change
    return unless table_exists?(:thredded_posts)

    def up
      execute "ALTER TABLE `thredded_posts` ENGINE = MyISAM"
      execute "ALTER TABLE `thredded_topics` ENGINE = MyISAM"
      execute "ALTER TABLE `thredded_categories` ENGINE = MyISAM"
    end

    def down
      execute "ALTER TABLE `thredded_posts` ENGINE = InnoDB"
      execute "ALTER TABLE `thredded_topics` ENGINE = InnoDB"
      execute "ALTER TABLE `thredded_categories` ENGINE = InnoDB"
    end
  end
end
