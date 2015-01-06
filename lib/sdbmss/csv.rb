
require 'csv'
require 'set'

module SDBMSS::CSV

  class << self

    def oracle_escape_str s
      s.gsub("'", "''")
    end

    # Prints report of frequency of chars in every value of every field.
    # This is useful for identifying chars with non-UTF8 encoding
    def find_infrequent_chars(csv_export_filename)

      chars_whitelist = Set.new([ "{", "}", "#" ])
      field_blacklist = Set.new(['COMMENTS', 'ENTRY_COMMENTS', 'MANUSCRIPT_BINDING', 'TITLE', 'MANUSCRIPT_LINK'])

      ids = {}

      freq = Hash.new

      filtered_headers = nil

      freq_threshold = 200

      CSV.foreach(File.expand_path(csv_export_filename), headers: true, skip_blanks: false) do |row|

        if !filtered_headers
          filtered_headers = row.headers.select { |h| !field_blacklist.member?(h) }
        end

        filtered_headers.each do |header|
          value = row[header]
          if !value.nil?
            bad_chars = value.chars.select { |ch| !chars_whitelist.member?(ch) }
            bad_chars.each do |char|
              freq[char] = { char: char, freq: 0, ids: Set.new } if freq[char].nil?
              # this check prevents memory usage from spiralling out of control
              if freq[char][:freq].to_i <= freq_threshold
                freq[char][:freq] += 1
                freq[char][:ids].add({ id: row['MANUSCRIPT_ID'], field: header })
              end
            end
          end
        end
      end

      freq_as_list = freq.values.select { |item| item[:freq] < freq_threshold }

      freq_as_list.sort! { |a,b| a[:freq] <=> b[:freq] }

      freq_as_list.each do |entry|
        char, freq, ids = entry[:char], entry[:freq], entry[:ids]
        ids.each do |id_record|
          id, field = id_record[:id], id_record[:field]
          puts "#{char},#{freq},#{id},#{field},http://sceti.library.upenn.edu/sdm_admin/update.cfm?id=#{id}&fS=1"
        end
      end

    end

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

      changelog_table = "MANUSCRIPT_CHANGE_LOG"
      changelog_table_seq = "MANUSCRIPT_CHANGE_LOG_ID_SEQ"

      reconcile(csv_export_filename, csv_cleaned_filename, table_name, fieldname) do |manuscript_id, original_fieldvalue, cleaned_fieldvalue|
        return_val = nil

        if !original_fieldvalue.nil?

          original_fieldvalue = original_fieldvalue.gsub(/\|+/, "|")

          cleaned_fieldvalue ||= ""

          if original_fieldvalue != cleaned_fieldvalue
            return_val = "update #{table_name} set #{fieldname} = '#{oracle_escape_str(cleaned_fieldvalue)}' WHERE MANUSCRIPT_ID = #{manuscript_id};\n"
            return_val += "insert into #{changelog_table} (CHANGEID, MANUSCRIPTID, CHANGEDCOLUMN, CHANGEDFROM, CHANGEDTO, CHANGETYPE, CHANGEDATE, CHANGEDBY) VALUES "
            return_val += "(#{changelog_table_seq}.NEXTVAL, #{manuscript_id}, '#{fieldname}', '#{oracle_escape_str(original_fieldvalue)}', '#{oracle_escape_str(cleaned_fieldvalue)}', 'C', SYSDATE, 'openrefine');"
          end
        else
          STDERR.puts "WARNING: field #{fieldname} is nil for manuscript id=#{manuscript_id}, skipping"
        end

        return_val
      end

    end

  end

end
