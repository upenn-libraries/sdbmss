
require 'io/console'

require 'sdbmss'
require 'sdbmss/csv'

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

end
