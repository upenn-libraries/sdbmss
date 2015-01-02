
require 'csv'

# Looks for changes in 2 CSV files and creates a .SQL file containing
# update queries for making the changes in the Oracle database.
#
# Here's an sqlplus command to create a copy of the manuscript table
# (don't use sqlplus's COPY, it doesn't play nice with column types in
# our MANUSCRIPT table). Note the index, which is very important for
# fast UPDATE queries.
#
# create table COPY_MANUSCRIPT as select * from MANUSCRIPT;
# CREATE INDEX copy_manuscript_index ON COPY_MANUSCRIPT (MANUSCRIPT_ID);
#
module SDBMSS::ReconcileCSV

  class << self

    def oracle_escape_str s
      s.gsub("'", "''")
    end

    # sanity check cleaned data against original csv and only do
    # updates that pertain to changed records
    def reconcile(csv_export_filename, csv_cleaned_filename, table_name="COPY_MANUSCRIPT", fieldname, &block)

      # This takes ~ 100M of RAM we only store the value, not the
      # complete row, because that would take way too much memory
      # (more than 1G as of Jan 2015)
      ids_to_fieldvalues = {}

      # puts "Reading original data..."
      CSV.foreach(File.expand_path(csv_export_filename), headers: true) do |row|
        ids_to_fieldvalues[row['MANUSCRIPT_ID']] = row[fieldname]
      end

      records_to_change = {}

      # puts "Examining cleaned data..."
      CSV.foreach(File.expand_path(csv_cleaned_filename), headers: true) do |row|
        manuscript_id = row['MANUSCRIPT_ID']

        sql = block.call(manuscript_id, ids_to_fieldvalues[manuscript_id], row[fieldname])

        if sql.present?
          records_to_change[manuscript_id] = sql
        end
      end

      puts "-- IMPORTANT! Run this as follows in a shell:"
      puts "--"
      puts "-- NLS_LANG=AMERICAN_AMERICA.UTF8 sqlplus64 thomakos@sdbm @updates.sql"
      puts "--"
      puts "-- The NLS_LANG environment variable MUST be set (and cannot be set inside sqlplus)"
      puts "-- in order for unicode to get inserted correctly"
      puts
      puts "-- this prevents sqlplus from interpreting ampsersands as user prompts"
      puts "set define off"
      puts
      puts "set autocommit off"
      puts "whenever SQLERROR EXIT ROLLBACK"

      records_to_change.each do |manuscript_id, sql|
        puts "select 'Doing #{manuscript_id}' from DUAL;"
        puts sql
      end

      puts "COMMIT;"
    end

    # This method handles fields generically in the MANUSCRIPT table
    def reconcile_field(csv_export_filename, csv_cleaned_filename, table_name, fieldname)

      reconcile(csv_export_filename, csv_cleaned_filename, table_name, fieldname) do |manuscript_id, original_fieldvalue, cleaned_fieldvalue|
        return_val = nil

        original_fieldvalue = original_fieldvalue.gsub(/\|+/, "|")

        cleaned_fieldvalue ||= ""

        if original_fieldvalue != cleaned_fieldvalue
          return_val = "update #{table_name} set #{fieldname} = '#{oracle_escape_str(cleaned_fieldvalue)}' WHERE MANUSCRIPT_ID = #{manuscript_id};"
        end

        return_val
      end

    end

  end

end
