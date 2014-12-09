require 'sdbmss'

namespace :sdbmss do

  desc "Re-create database with new migration from a copy of the live Oracle db"
  task migrate_legacy_data: :environment do

    `echo "drop database sdbm_rails" | mysql -u root`

    Rake::Task['db:create'].invoke

    # Rake::Task['db:schema:load'].invoke
    Rake::Task['db:migrate'].invoke

    SDBMSS::Legacy.migrate

  end

end
