require 'sdbmss'
require 'sdbmss/reconcilecsv'

namespace :sdbmss do

  desc "Re-create database with new migration from a copy of the live Oracle db"
  task :migrate_legacy_data, [:fast_flag] => [:environment] do |t, args|

    `echo "drop database #{ENV["SDBMSS_DB_NAME"]}" | mysql -u root`

    Rake::Task['db:create'].invoke

    # Rake::Task['db:schema:load'].invoke
    Rake::Task['db:migrate'].invoke

    SDBMSS::Legacy.migrate(fast: args[:fast_flag] == 'true')

  end

  desc "Generate SQL output of UPDATE queries for provenance data changed between the 2 files"
  task :reconcile_field, :export_filename, :cleaned_filename, :table_name, :field_name do |t, args|
    if args[:export_filename].present? &&
       args[:cleaned_filename].present? &&
       args[:table_name].present? &&
       args[:field_name].present?
      SDBMSS::ReconcileCSV.reconcile_field(
        args[:export_filename],
        args[:cleaned_filename],
        args[:table_name],
        args[:field_name])
    else
      puts "ERROR: an argument is missing"
    end
  end

end
