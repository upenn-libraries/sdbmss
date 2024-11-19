# coding: utf-8

module SDBMSS::VIAFReconciliation

  class << self

    def write_file(names_and_viaf_ids, filename)
      ::CSV.open(filename, "wb") do |csv|
        names_and_viaf_ids.each do |key, val|
          csv << [key, val]
        end
      end
    end

    # examines a .csv file containing names and VIAF IDs, and appends
    # to it any new Name records in the database, reconciling them
    # with VIAF.
    def reconcile_names(filename)
      count = 0
      names_and_viaf_ids = {}

      if File.exist?(filename)
        ::CSV.read(filename).each do |row|
          names_and_viaf_ids[row[0]] = row[1]
        end
      end

      names = Name.where("viaf_id is null").order(id: :asc)
      names.find_each(batch_size: 100) do |name|
        # for some reason, the 'Ardabili' name causes VIAF request to never return!
        if names_and_viaf_ids[name.name].blank? && name.name != 'Ardabili, Mu?ammad ibn Ya?yá ibn A?mad'
          puts "checking #{name}"

          try = 0
          request_successful = false

          while !request_successful && try < 3
            suggestions = Name.suggestions(name.name, check_if_name_already_exists: false, debug: true)
            found = false

            if suggestions[:error].blank?
              request_successful = true

              # 1st pass: find an exact match, by str equality or substring
              suggestions[:results].each do |result|
                if !found && (name.name.upcase == result[:name].upcase || result[:name].upcase.include?(name.name.upcase))
                  puts "exact match: #{result[:name]}, viaf id=#{result[:viaf_id]}"
                  names_and_viaf_ids[name.name] = result[:viaf_id]
                  found = true
                end
              end

              # 2nd pass: find best match by string similarity ONLY if
              # name isn't just a single string
              if !found && name.name.split.length >= 2
                if suggestions[:results].length > 0
                  suggestions[:results].each { |result|
                    result[:score] = Levenshtein.normalized_distance(name.name, result[:name])
                  }
                  best = suggestions[:results].min { |a, b| a[:score] <=> b[:score] }
                  puts "best match: #{best[:name]}, viaf id=#{best[:viaf_id]}"
                  names_and_viaf_ids[name.name] = best[:viaf_id]
                  found = true
                end
              end

              # no match, so set VIAF ID as -1
              if !found
                names_and_viaf_ids[name.name] = "-1"
              end

              count += 1

              # write out to disk every 30 records
              write_file(names_and_viaf_ids, filename) if count % 30 == 0
            else
              puts "got http error, sleeping and trying again"
              sleep 5
              try += 1
            end
          end

        end
      end

      # write out any remaining records
      write_file(names_and_viaf_ids, filename)
    end

    # Update the Name records in the database with VIAF IDs found in
    # the passed-in CSV file. This is safe to run multiple times, it
    # will not overwrite VIAF IDs that already exist in the database.
    def update_names(filename)
      ::CSV.read(filename).each do |row|
        name = row[0]
        viaf_id = row[1]
        if viaf_id != "-1"
          if (name_record = Name.find_by(name: name)).present?
            if name_record.viaf_id.blank?
              puts "Updating Name ##{name_record.id}: #{name_record.name}"
              name_record.viaf_id = viaf_id
              if !name_record.save
                puts "Error updating name ##{name_record.id}: #{name_record.name}: #{name_record.errors.messages}"
              end
            else
              puts "Skipping Name ##{name_record.id}: #{name_record.name}, already has a VIAF ID"
            end
          else
            puts "Warning! Name not found in database: #{name}"
          end
        end
      end
    end

  end

end

