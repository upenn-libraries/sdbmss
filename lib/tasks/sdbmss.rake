
require 'io/console'

require 'sdbmss'
require 'sdbmss/csv'

namespace :sdbmss do

  desc "Re-create database with new migration from a copy of the live Oracle db"
  task :migrate_legacy_data do |t, args|

    # This wrapper task exists so we get a chance to set an
    # environment variable before Rails bootstrap phrase (which is
    # triggered by Rake's :environment arg).

    ENV['SDBMSS_SUNSPOT_AUTOINDEX'] = 'false'

    Rake::Task['sdbmss:migrate_legacy_data_real'].invoke
  end

  # DO NOT RUN THIS DIRECTLY: run migrate_legacy_data instead
  task :migrate_legacy_data_real => :environment do |t, args|
    if Rails.env == "development"
      Rake::Task['db:drop'].invoke

      Rake::Task['db:create'].invoke

      Rake::Task['db:schema:load'].invoke

      Rake::Task['db:seed'].invoke

      SDBMSS::Legacy.migrate
    else
      puts "ERROR: Rails environment is set to #{Rails.env}. but you're only allowed to run this task in development. Doing nothing and exiting."
    end
  end

  desc "Generate SQL output of UPDATE queries for provenance data changed between the 2 files"
  task :reconcile_field, :export_filename, :cleaned_filename, :table_name, :field_name do |t, args|
    if args[:export_filename].present? &&
       args[:cleaned_filename].present? &&
       args[:table_name].present? &&
       args[:field_name].present?
      SDBMSS::CSV.reconcile_field(
        args[:export_filename],
        args[:cleaned_filename],
        args[:table_name],
        args[:field_name])
    else
      puts "ERROR: an argument is missing"
    end
  end

  desc "Generate report of infrequently occuring chars"
  task :find_infrequent_chars, :export_filename do |t, args|
    if args[:export_filename].present?
      SDBMSS::CSV.find_infrequent_chars args[:export_filename]
    else
      STDERR.puts "ERROR: specify a .csv file as argument"
    end
  end

  desc "Generate report of invalid materials"
  task :find_invalid_materials, [:export_filename] => :environment do |t, args|
    SDBMSS::CSV.find_invalid_materials args[:export_filename]
  end

  desc "Generate report of 'duplicates'"
  task :report_duplicates, [:export_filename] => :environment do |t, args|
    first = true
    Rails.logger.level = 1
    count = 0
    # Note that at batch_size=100, the process stops growing at
    # ~260M. At batch_size=1000, proc grows to 1G.
    Manuscript.all.order(:id).find_each(batch_size: 100) do |manuscript|
      entries = manuscript.entries

      needs_review = entries.any? { |entry| entry.secondary_source.present? }

      entries.each do |entry|
        hash = entry.as_flat_hash
        if first
          puts ::CSV.generate_line(["needs_review"] + hash.keys)
          first = false
        end
        puts ::CSV.generate_line([needs_review] + hash.values)
      end
      count += 1
    end
  end

  desc "Change a user's password"
  task :change_password => :environment do |t, args|
    # devise doesn't seem to make available a rake task like this, so
    # I made one.

    print "Username: "
    username = STDIN.gets.chomp
    u = User.where(:username => username).first
    if !u.nil?
      print "Enter new password: "
      password = STDIN.noecho(&:gets).chomp
      puts
      print "Confirm password: "
      password_confirmation = STDIN.noecho(&:gets).chomp
      puts

      if password == password_confirmation
        u.password = password
        u.password_confirmation = password_confirmation
        u.save!
        puts "Password changed."
      else
        puts "Error: passwords didn't match"
      end
    else
      puts "Couldn't find user '#{username}'"
    end
  end

  desc "Create reference data"
  task :create_reference_data => :environment do |t, args|

    ActiveRecord::Base.transaction do
      SDBMSS::ReferenceData.create_all
    end

  end

  # requested by Toby Burrows
  desc "Export legacy catalog table as CSV to stdout"
  task :export_catalogs => :environment do |t, args|
    columns = %w[MANUSCRIPTCATALOGID CAT_DATE CAT_ID SELLER SELLER2 INSTITUTION MS_COUNT CAT_AUTHOR WHETHER_MSS CURRENT_LOCATION LOCATION_CITY LOCATION_COUNTRY ONLINE_LINK ELEC_CAT_FORMAT ELEC_CAT_OPENACCESS ALT_CAT_DATE ADDED_ON LAST_MODIFIED COMMENTS CATALOGING_TYPE SDBM_STATUS]
    puts ::CSV.generate_line columns
    SDBMSS::Util.batch(SDBMSS::Legacy.get_legacy_db_conn,
                       'select * from MANUSCRIPT_CATALOG where HIDDEN_CAT is null and ISDELETED is null ORDER BY CAT_DATE, CAT_ID',
                       silent: true) do |row, ctx|
      values = columns.map { |col| row[col] }
      puts ::CSV.generate_line values
    end
  end

  desc "Create VIAF Name file"
  task :create_viaf_name_file, [:filename] => :environment do |t, args|
    filename = args[:filename]
    if filename.present?
      SDBMSS::VIAFReconciliation.reconcile_names(filename)
    else
      puts "Error: specify a file"
    end
  end

  desc "Update Name records with VIAF IDs"
  task :update_names, [:filename] => :environment do |t, args|
    filename = args[:filename]
    if filename.present?
      SDBMSS::VIAFReconciliation.update_names(filename)
    else
      puts "Error: specify a file"
    end
  end

  desc "Update all counter_cache fields"
  task :update_counter_cache => :environment do |t, args|
    puts "WARNING: this won't work for counter_cache fields that should account for soft deletions"
    SDBMSS::Util.update_counter_cache_all
    puts "Done."
  end

  # Fix data in a bad migration of the legacy db; this task is a one-time fix, can be safely removed later.
  desc "Fix dupe entry_authors"
  task :fix_entry_authors_dupes => :environment do |t, args|
    puts "This permanently deletes duplicate entry_author records for Entries! Are you SURE you want to do this ? [y/n] "
    if STDIN.gets.chomp != 'y'
      puts "Aborting and exiting."
    end

    puts "Looking for duplicates"
    sql = "select * from (select distinct entry_id, count(*) as x from entry_authors group by entry_id, observed_name, author_id, role) t where x > 1;"
    ActiveRecord::Base.connection.execute(sql).each do |row|
      puts "examining Entry #{row[0]}"
      entry = Entry.find(row[0])
      unique = []
      entry.entry_authors.each do |entry_author|
        deleted = false
        unique.each do |unique_entry_author|
          if entry_author.entry_id == unique_entry_author.entry_id &&
             entry_author.author_id == unique_entry_author.author_id &&
             entry_author.observed_name == unique_entry_author.observed_name &&
             entry_author.role == unique_entry_author.role
            puts "Deleting entry_author id=#{entry_author.id}"
            entry_author.destroy!
            deleted = true
          end
        end
        if !deleted
          unique << entry_author
        end
      end
    end
    puts "Resetting counters"
    Name.unscoped.find_each(batch_size: 500).each do |name|
      Name.reset_counters(name.id, :entry_authors)
    end
    puts "You should now run 'bundle exec rake sunspot:reindex'"
  end

end
