
require 'date'
require 'set'

# Code pertaining to migration of legacy data, which we fetch from a
# MySQL database that's a copy of the Oracle production database.
module SDBMSS::Legacy

  # module-level methods
  class << self

    VALID_SOLD_TYPES = Sale::SOLD_TYPES.map(&:first)

    VALID_ALT_SIZE_TYPES = Entry::ALT_SIZE_TYPES.map { |item| item[0] }

    # mapping of 'rogue' codes to normalized values
    ALT_SIZE_CODES_TO_NORMALIZE = {
      "[O]" => "O",
      "[Q]" => "Q",
      "12" => "12mo",
      "16" => "16mo",
      "18" => "18mo",
      "24" => "24mo",
      "32," => "32mo",
      "32ND" => "32mo",
      "32NDS" => "32mo",
      "D" => "12mo",
      "LD" => "12mo",
      "LF" => "F",
      "LF," => "F",
      "LF, 2" => "F",
      "LO" => "O",
      "LO," => "O",
      "LQ" => "Q",
      "LSQF" => "F",
      "LSQQ" => "Q",
      "OBD" => "12mo",
      "OBF" => "F",
      "OBO" => "O",
      "OBQ" => "Q",
      "OF" => "F",
      "OQ" => "Q",
      "Q,F" => "Q",
      "S" => "16mo",
      "S32," => "32mo",
      "SD" => "12mo",
      "SF" => "F",
      "SF," => "F",
      "SF/Q" => "F",
      "Sm F" => "F",
      "Sm Q" => "Q",
      "SO" => "O",
      "SOBQ" => "Q",
      "SQ" => "Q",
      "SQ12" => "12mo",
      "SQ18" => "18mo",
      "SQ24" => "24mo",
      "SQ32" => "32mo",
      "SQD" => "12mo",
      "SQF" => "F",
      "SQO" => "O",
      "SQS" => "16mo",
      "SQSF" => "F",
      "SSQQ" => "Q",
      "T" => "32mo",
      "TQ" => "Q",
    }

    VALID_CIRCA_TYPES = [
      "C",
      "C?",
      "CCENT",
      "C1H",
      "C2H",
      "C1Q",
      "C2Q",
      "C3Q",
      "C4Q",
      "CEARLY",
      "CMID",
      "CLATE",
    ]

    VALID_CURRENCY_TYPES = Sale::CURRENCY_TYPES.map { |item| item[0] }

    VALID_MATERIALS = EntryMaterial::MATERIAL_TYPES.map { |item| item[0] }

    LEGACY_SOLD_CODES = {
      "UNKNOWN" => Sale::TYPE_SOLD_UNKNOWN,
      "YES" => Sale::TYPE_SOLD_YES,
      "NO" => Sale::TYPE_SOLD_NO,
      "WD" => Sale::TYPE_SOLD_WITHDRAWN,
    }

    LEGACY_MATERIAL_CODES = {
      "C" => "Clay",
      "P" => "Paper",
      "PY" => "Papyrus",
      "S" => "Silk",
      "V" => "Parchment",
    }

    REGEX_COMMON_TITLE = /\[(.+)\]/

    # Converts the legacy circa/year combination to an Array of
    # [normalized start date, normalized end date, uncertain_in_source
    # flag, supplied_by_data_entry flag].
    #
    # Important note: the logic here takes into account the data entry
    # standards used in the SDBM: for example, when paired with a
    # circa code, date values ending in 50 are used to indicate a
    # century ("1250" = 13th century). It also accounts for other
    # idiosyncracies that were unearthed in discussions with Lynn and
    # others. So stuff that might seem arbitrary probably isn't.
    #
    # If a circa has an exact date that falls within its range, we
    # normalize to the full range.
    #
    # If the date doesn't end with a 50 to indicate the century, and
    # is outside the range, then use the exact date for normalization.
    def normalize_circa_and_date(manuscript_id, circa, date)
      circa_original = circa

      if circa == 'c1h2'
        circa = 'C1H'
      end

      circa, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(circa)

      start_date, end_date = date, date
      before, after = false, false

      if circa.present?
        # see if we can match to a valid circa type if we ignore spaces
        # and case
        circa_normalized = circa.upcase.gsub(/ /, '')
        VALID_CIRCA_TYPES.each do |valid_type|
          if circa_normalized == valid_type
            circa = valid_type
          end
        end
      end

      if circa == '+' || circa == 'after'
        return EntryDate.parse_observed_date("after #{date}")
      elsif circa == '-' || circa == 'before'
        return EntryDate.parse_observed_date("before #{date}")
      elsif circa == '+/-' || circa == 'c+/-'
        return EntryDate.parse_observed_date("circa #{date}")
      elsif circa.present?
        if date.present?
          before = !! /-/.match(circa)
          after = !! /\+/.match(circa)
          circa_without_modifier = circa.upcase.gsub(/[\-\+]/, '')

          if VALID_CIRCA_TYPES.member?(circa_without_modifier)
            century = (date[0..-3].to_i + 1).to_s
            decade = date[-2,2]

            date_is_out_of_circa_period = false

            case circa_without_modifier
            when 'C'
              start_date, end_date = EntryDate.parse_observed_date("circa #{date}")
            when 'CCENT'
              # note: we treat 'CCENT 1200' as meaning the 13th
              # century though it's ambiguous (could be used to mean
              # 12th century)
              start_date, end_date = EntryDate.parse_observed_date("#{century} century")
            when 'C1H'
              if decade.to_i <= 50
                start_date, end_date = EntryDate.parse_observed_date("first half of #{century} century")
              else
                date_is_out_of_circa_period = true
              end
            when 'C2H'
              if decade.to_i >= 50
                start_date, end_date = EntryDate.parse_observed_date("second half of #{century} century")
              else
                date_is_out_of_circa_period = true
              end
            when 'C1Q'
              if (decade.to_i >= 0 && decade.to_i <= 25) || decade.to_i == 50
                start_date, end_date = EntryDate.parse_observed_date("first quarter of #{century} century")
              else
                date_is_out_of_circa_period = true
              end
            when 'C2Q'
              if (decade.to_i >= 25 && decade.to_i <= 50) || decade.to_i == 50
                start_date, end_date = EntryDate.parse_observed_date("second quarter of #{century} century")
              else
                date_is_out_of_circa_period = true
              end
            when 'C3Q'
              if (decade.to_i >= 50 && decade.to_i <= 75) || decade.to_i == 50
                start_date, end_date = EntryDate.parse_observed_date("third quarter of #{century} century")
              else
                date_is_out_of_circa_period = true
              end
            when 'C4Q'
              if (decade.to_i >= 75 && decade.to_i <= 99) || decade.to_i == 50
                start_date, end_date = EntryDate.parse_observed_date("fourth quarter of #{century} century")
              else
                date_is_out_of_circa_period = true
              end
            when 'CEARLY'
              start_date, end_date = EntryDate.parse_observed_date("early #{century} century")
            when 'CMID'
              start_date, end_date = EntryDate.parse_observed_date("mid #{century} century")
            when 'CLATE'
              start_date, end_date = EntryDate.parse_observed_date("late #{century} century")
            end

            # if date value is weirdly outside the circa period,
            # normalize it as a single date.
            if date_is_out_of_circa_period
              start_date = date
              end_date = (start_date.to_i + 1).to_s
            end

            if before
              period = end_date.ends_with?("0") ? 100 : 101
              start_date = (end_date.to_i - period).to_s
            elsif after
              if circa_without_modifier != 'CCENT'
                period = start_date.ends_with?("0") ? 101 : 100
                end_date = (start_date.to_i + period).to_s
              else
                # we want "ccent+ 1250" to normalize to "13th to 14th century"
                end_date = EntryDate.parse_observed_date("#{century.to_i + 1} century")[1]
              end
            end
          else
            create_issue('MANUSCRIPT', manuscript_id, "bad_circa", "can't handle: #{circa_original} #{date}, treating this as date without a circa")
            start_date = date
            end_date = (start_date.to_i + 1).to_s
          end
        else
          # has circa but no date, which we just ignore.
          # create_issue('MANUSCRIPT', manuscript_id, "circa_without_date", "#{circa_original} #{date}")
        end
      else
        # no circa
        if date.present?
          start_date = date
          end_date = (start_date.to_i + 1).to_s
        end
      end
      return [start_date, end_date, uncertain_in_source, supplied_by_data_entry]
    end

    # Returns db connection to the legacy database in MySQL.
    def get_legacy_db_conn
      Mysql2::Client.new(:host => ENV["SDBMSS_LEGACY_DB_HOST"],
                         :username => ENV["SDBMSS_LEGACY_DB_USER"],
                         :database => ENV["SDBMSS_LEGACY_DB_NAME"],
                         :password => ENV["SDBMSS_LEGACY_DB_PASSWORD"],
                        )
    end

    def create_user(row, ctx)

      role = nil
      case
      when row['PERMISSION'] == 'entry'
        role = 'contributor'
      when row['PERMISSION'] == 'edit'
        role = 'editor'
      when row['PERMISSION'] == 'admin'
        role = 'admin'
      end

      password = row['PENNKEYPASS']
      user = User.new(username: row['PENNKEY'],
                          email: row['PENNKEY'] + "@upenn.edu",
                          password: password,
                          role: role)
      # skip validations because Devise considers some existing
      # passwords to be invalid, but we don't care.
      user.save!(validate: false)

    end

    USER_CACHE = {}

    def get_or_create_user(username)
      if username
        if ! USER_CACHE.member?(username)
          user = User.where(username: username).first
          if user.nil?
            user = User.create!(
              username: username,
              email: username + '@nowhere.com',
              password: 'somethingunguessable'
              )
          end
          USER_CACHE[username] = user
        end
      end
      USER_CACHE[username]
    end

    PLACE_CACHE = {}

    def get_or_create_place(name)
      PLACE_CACHE[name] ||= Place.where(name: name).first_or_create!
    end

    LANGUAGE_CACHE = {}

    def get_or_create_language(name)
      LANGUAGE_CACHE[name] ||= Language.where(name: name).order(nil).first_or_create!
    end

    NAME_CACHE = {}

    # This get_or_create first checks that the name exists with ANY
    # role; if it does, it sets the role, otherwise it creates that
    # name. role is a symbol that corresponds to one of Name's flags
    # (is_artist, is_scribe, etc)
    def get_or_create_name(name_str, role, extra_attrs: nil)
      name_obj = nil
      if name_str
        if ! NAME_CACHE.member?(name_str)
          name_obj = Name.where(name: name_str).order(nil).first
          if name_obj.nil?
            attrs = {
              name: name_str,
              reviewed: true
            }
            attrs[role] = true
            attrs.merge!(extra_attrs) if !extra_attrs.nil?
            name_obj = Name.create!(attrs)
          end
          NAME_CACHE[name_str] = name_obj
        else
          name_obj = NAME_CACHE[name_str]
        end
        # if name doesn't have that role set yet, set it
        if !name_obj.send(role)
          # puts "adding role #{role} to name '#{name_obj}'"
          name_obj.send("#{role}=", true)
          name_obj.save!
        end
      end
      name_obj
    end

    def get_or_create_agent(name)
      get_or_create_name(name, :is_provenance_agent)
    end

    def get_or_create_artist(name, extra_attrs: nil)
      get_or_create_name(name, :is_artist, extra_attrs: extra_attrs)
    end

    def get_or_create_author(name, extra_attrs: nil)
      get_or_create_name(name, :is_author, extra_attrs: extra_attrs)
    end

    def get_or_create_scribe(name)
      get_or_create_name(name, :is_scribe)
    end

    def get_author(name)
      NAME_CACHE[name]
    end

    SOURCE_CACHE = {}

    def get_source(id)
      SOURCE_CACHE[id]
    end

    ROLE_CODES = EntryAuthor::TYPES_ROLES.map(&:first)

    # Splits an author string into name and roles.
    # ie. for "Jeff (Ed) (Tr)", this returns ["Jeff", ["Ed", "Tr"]]
    def split_author_role_codes(str)
      # we're restrictive in our matching of role codes because
      # there's all kinds of crap inside parens in these strings
      author = str
      roles = []
      if str.present?
        ROLE_CODES.each do |code|
          # sometimes there's a period.
          author_portion = author.gsub("(#{code})", "").gsub("(#{code}.)", "")
          if author != author_portion
            author = author_portion.strip
            roles << code
          end
        end
      end
      return [author, roles]
    end

    # parse the brackets and question marks from strings. returns an
    # array of 3 items: a string stripped of certainty marks, boolean
    # indicating uncertain_in_source, boolean indicating
    # supplied_by_data_entry.
    def parse_certainty_indicators(s)
      # be very restrictive in our matching here: since there is all
      # kinds of crazy stuff in strings, if we don't find EXACTLY what
      # we're looking for, leave it alone

      return [s, false, false] if s.blank?

      supplied_by_data_entry = false
      uncertain_in_source = false

      # look for ? at end, brackets notwithstanding
      if s.gsub(/[\[\]]/, "").strip.end_with?("?")
        # replace last occurence of ?. this ignores any question marks
        # in the middle of the string, which does happen
        without_question_mark = s.reverse.sub("?", "").reverse
        uncertain_in_source = true
      else
        without_question_mark = s.dup
      end

      without_question_mark.strip!

      # match only if [] occur EXACTLY at beg and end, b/c there are
      # strings with [] in the middle, which can mean God knows what.
      if without_question_mark[0] == '[' && without_question_mark[-1] == ']'
        supplied_by_data_entry = true
        bare = without_question_mark[1..-2].strip
      else
        bare = without_question_mark
      end

      # Lynn says flags should be mutually exclusive: if both are
      # true, use supplied_by_data_entry and discard uncertain_in_source
      if uncertain_in_source && supplied_by_data_entry
        uncertain_in_source = false
      end

      return [bare, uncertain_in_source, supplied_by_data_entry]
    end

    def parse_common_title(title)
      # a common title exists ONLY if it's a bracketed str that occurs
      # at the end of the title. This restrictive match ensures we
      # leave other kinds of funky data alone.

      common_title = nil
      if title.present?
        if title.end_with?("]")
          last_found = -1
          while !(pos = title.index("[", last_found + 1)).nil?
            last_found = pos
          end
          if last_found != -1
            common_title = title[last_found + 1 .. -2]
            title = title[0 .. last_found - 1].strip
          end
        end
      end
      return title, common_title
    end

    # given an Entry object, appends str to the other_info str,
    # prepending the searchable token MIGRATION_ISSUE.  We use this to
    # store pieces of information that couldn't be migrated into
    # normalized fields, or that don't have a proper place in the new
    # data model.
     def append_comment_to_other_info(other_info, str)
      if other_info.present?
        other_info += "\n"
      else
        other_info = ""
      end
      other_info += "MIGRATION_ISSUE: #{str}"
      other_info
     end

    # Do the migration
    def migrate

      # paper_trail slows down migration by 4x's; we don't need to
      # audit anything here, so disable it.
      PaperTrail.enabled = false

      ActiveRecord::Base.record_timestamps = false

      Rails.configuration.sdbmss_index_after_update_enabled = false

      # set log level above :debug, to suppress ActiveRecord query
      # logging, which slows things down a lot. this only accepts
      # integers, not symbols. 1 = info
      Rails.logger.level = 1

      legacy_db = get_legacy_db_conn

      wrap_transaction = Proc.new do |process_batch|
        ActiveRecord::Base.transaction do
          process_batch.call
        end
      end

      puts "Doing some sanity checks on legacy data"

      verify_catalog_data(legacy_db)

      puts "Migrating Users"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_USER') do |row,ctx|
        create_user(row, ctx)
      end

      puts "Migrating Author records (first pass)"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_AUTHOR ORDER BY MANUSCRIPTAUTHORID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_author_from_row_pass1(row, ctx)
      end

      puts "Migrating Artist records (first pass)"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_ARTIST ORDER BY MANUSCRIPTARTISTID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_artist_from_row_pass1(row, ctx)
      end

      # create an 'Unknown' source to attach to entries that don't
      # have one; do this before catalog migration so it's id=1
      unknown_source = Source.create!(
        title: "Unknown - This source is a container for legacy records missing valid source information",
        source_type: SourceType.unpublished,
      )

      # special case for handling records from Jordanus
      jordanus = Source.create!(
        title: "Jordanus",
        source_type: SourceType.unpublished,
      )

      puts "Migrating Source records"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_CATALOG ORDER BY MANUSCRIPTCATALOGID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        begin
          create_source_from_row(row, ctx)
        rescue
          puts "ERROR ON CATALOG ID=#{row["MANUSCRIPTCATALOGID"]}"
          raise
        end
      end

      puts "Migrating Place records (first pass)"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_PLACE ORDER BY MANUSCRIPTPLACEID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_place_from_row_pass1(row, ctx)
      end

      puts "Migrating Manuscript records"

      # we use a set so we only need to store one record per 'duplicate set'
      duplicates = Set.new

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT ORDER BY MANUSCRIPT_ID',
                         ctx: {duplicates: duplicates, unknown_source: unknown_source, jordanus: jordanus, db: legacy_db},
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_entry_from_row(row, ctx)
      end

      puts "Creating Agent entities for non-unique names in Provenance"

      create_agent_entities_for_provenance(legacy_db)

      # puts "Second pass over Author records"

      # SDBMSS::Util.batch(legacy_db,
      #                    'SELECT * FROM MANUSCRIPT_AUTHOR ORDER BY MANUSCRIPTAUTHORID',
      #                    batch_wrapper: wrap_transaction) do |row,ctx|
      #   create_author_from_row_pass2(row, ctx)
      # end

      # puts "Second pass over Artist records"

      # SDBMSS::Util.batch(legacy_db,
      #                    'SELECT * FROM MANUSCRIPT_ARTIST ORDER BY MANUSCRIPTARTISTID',
      #                    batch_wrapper: wrap_transaction) do |row,ctx|
      #   create_artist_from_row_pass2(row, ctx)
      # end

      puts "Second pass over Place records"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_PLACE ORDER BY MANUSCRIPTPLACEID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_place_from_row_pass2(row, ctx)
      end

      puts "Migrating MANUSCRIPT_CHANGE_LOG records"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_CHANGE_LOG ORDER BY CHANGEID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_manuscript_changelog_from_row(row, ctx)
      end

      puts "Making Manuscript records from 'DUPLICATE_MS' records (#{duplicates.length} total)"

      create_manuscripts_from_duplicates(duplicates)

      puts "Making EntryManuscript records from 'POSSIBLE_DUPS' records"

      # we need to have created Manuscript records in
      # #create_manuscripts_from_duplicates before this step
      SDBMSS::Util.batch(legacy_db,
                         'select MANUSCRIPT_ID, POSSIBLE_DUPS from MANUSCRIPT where (ISDELETED IS NULL OR ISDELETED != "y") and (POSSIBLE_DUPS is not null OR length(POSSIBLE_DUPS) > 0)',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_entry_manuscripts_from_possible_dups(row, ctx)
      end

      puts "Migrating current_location to Manuscripts"

      SDBMSS::Util.batch(legacy_db,
                         'select MANUSCRIPT_ID, CURRENT_LOCATION from MANUSCRIPT where (ISDELETED IS NULL OR ISDELETED != "y") and CURRENT_LOCATION is not null and length(CURRENT_LOCATION) > 0',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        entry = Entry.find(row['MANUSCRIPT_ID'])
        manuscript = entry.manuscript

        # if there's a Manuscript, tack the current_location info to
        # it. Otherwise, tack the info on to 'other_info' field.
        if manuscript.present?
          location_already_populated = manuscript.location.present?
          manuscript.location = "" if !location_already_populated

          # only append str if it's not already included in the field
          if !manuscript.location.include?(row['CURRENT_LOCATION'])
            # if location_already_populated
            #   create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], "current_location", "Warning: more than one current_location found for Manuscript ID = #{manuscript.id}")
            # end
            manuscript.location += "; " if manuscript.location.length > 0
            manuscript.location << row['CURRENT_LOCATION']
            manuscript.save!
          end
        else
          # Note that we do NOT create a Manuscript (code commented
          # out below) for Entries that don't already have one, bc
          # this creates a lot of nonsensical Manuscript records whose
          # only purpose is to contain this piece of data.

          # puts "WARNING: creating a Manuscript so that current_location can be migrated"
          # manuscript = Manuscript.create!

          # manuscript_entry = EntryManuscript.create!(
          #   entry_id: row['MANUSCRIPT_ID'],
          #   manuscript: manuscript,
          #   relation_type: EntryManuscript::TYPE_RELATION_IS,
          # )
          entry.other_info = append_comment_to_other_info(entry.other_info, "Last known location for this Entry is #{row['CURRENT_LOCATION']}, couldn't store this in the Manuscript record because there is none.")
          entry.save!
        end

      end

    end

    CURRENT_YEAR = DateTime.now.year

    def validate_fuzzy_date(date, row)
      if date
        valid = true
        if ! [4, 6, 8].member?(date.length)
          valid = false
        end
        year, mon, day = date.slice(0, 4), date.slice(4, 2), date.slice(6, 2)
        if year && year != '0000' && year.to_i > CURRENT_YEAR
          valid = false
        end
        if mon && mon != '00' && mon.to_i > 12
          valid = false
        end
        if day && day != '00' && day.to_i > 31
          valid = false
        end
        if !valid
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], "bad_date", "Bad date '#{date}'")
        end
      end
    end

    def validate_language(lang, row)
      # if "?" in lang:
      #     create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], "language", "Get rid of ? in '%s'" % (lang,))
      if (lang.include?("[") && !lang.include?("]")) ||
         (lang.include?("]") && !lang.include?("["))
        create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], "language", "Missing bracket in '#{lang}'")
      end
    end

    def verify_catalog_data(db)

      results = db.query("show indexes from MANUSCRIPT WHERE Key_name = \"manuscript_cat_tbl_id\";")
      if results.count == 0
        db.query("CREATE INDEX manuscript_cat_tbl_id ON MANUSCRIPT (CAT_TBL_ID);")
      end

      results = db.query("show indexes from MANUSCRIPT_CATALOG WHERE Key_name = \"manuscript_catalog_id\";")
      if results.count == 0
        db.query("CREATE INDEX manuscript_catalog_id ON MANUSCRIPT_CATALOG (MANUSCRIPTCATALOGID);")
      end

      results = db.query("""select count(*) as mycount from MANUSCRIPT inner join MANUSCRIPT_CATALOG
        on MANUSCRIPT.CAT_TBL_ID = MANUSCRIPTCATALOGID
        where
        (MANUSCRIPT.ISDELETED != 'y' OR MANUSCRIPT.ISDELETED IS NULL)
        and (
        MANUSCRIPT.SELLER != MANUSCRIPT_CATALOG.SELLER
        OR MANUSCRIPT.SELLER2 != MANUSCRIPT_CATALOG.SELLER2
        OR MANUSCRIPT.INSTITUTION != MANUSCRIPT_CATALOG.INSTITUTION
        OR MANUSCRIPT.CAT_DATE != MANUSCRIPT_CATALOG.CAT_DATE
        OR MANUSCRIPT.CAT_ID != MANUSCRIPT_CATALOG.CAT_ID)""")

      if results.first['mycount'] != 0
        raise "ERROR: There are MANUSCRIPT records whose source fields don't match correspoending fields in MANUSCRIPT_CATALOG table"
      end

      results = db.query("""select count(*) as mycount from MANUSCRIPT
        where MANUSCRIPT.CAT_TBL_ID is null
        and (MANUSCRIPT.ISDELETED != 'y' OR MANUSCRIPT.ISDELETED IS NULL)
        and (length(MANUSCRIPT.SELLER2) > 0
        OR length(MANUSCRIPT.SELLER2) > 0
        OR length(MANUSCRIPT.INSTITUTION) > 0
        OR length(MANUSCRIPT.CAT_DATE) > 0
        OR length(MANUSCRIPT.CAT_ID) > 0)""")

      if results.first['mycount'] != 0
        raise "ERROR: There are MANUSCRIPT records with no FK to MANUSCRIPT_CATALOG but with values in the catalog fields"
      end
    end

    def create_issue(table_name, record_id, issue_type, explanation)
      LegacyDataIssue.create!(
        table_name: table_name,
        record_id: record_id,
        issue_type: issue_type,
        explanation: explanation,
      )
      puts "Warning: #{table_name} ID: #{record_id}: #{explanation}"
    end

    def create_entry_from_row(row, ctx)

      duplicates = ctx[:duplicates]

      begin
        entry = create_entry_and_all_associations(row, ctx[:unknown_source], ctx[:jordanus], ctx[:db])
      rescue Exception => e
        puts "error on id=#{row['MANUSCRIPT_ID']}"
        raise
      end

      if row['DUPLICATE_MS'].present?
        duplicates.add(row['DUPLICATE_MS'])
      end

    end

    def create_entry_and_all_associations(row, unknown_source, jordanus, db)

      date = row['CAT_DATE']
      date = nil if date == '00000000'

      validate_fuzzy_date(date, row)

      # we regard Nulls as meaning approved, since thats how they seem
      # to be treated.
      approved = row['ISAPPROVED'] != 'n'

      deleted = row['ISDELETED'] == 'y'

      other_info = row['COMMENTS'] || ""

      sale_fields = [ 'SELLER', 'SELLER2', 'BUYER', 'PRICE', 'CURRENCY', 'SOLD' ]
      has_sale_information = sale_fields.any? { |field| row[field].present? }

      # entries MUST have a source.

      source = nil
      if (!deleted) and row['CAT_TBL_ID'].present?
        source = get_source(row['CAT_TBL_ID'])
        if source.nil?
          # there are only 3 of these cases
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'bad_catalog_fk', "WARNING: entry ID=#{row['MANUSCRIPT_ID']} has bad Catalog foreign key #{row['CAT_TBL_ID']}")
        end
      end

      if source.nil?
        # about 9000 Manuscript records with Jordanus in SECONDARY_SOURCE have CAT_TBL_ID = null
        # There are also 464 records that DO have CAT_TBL_ID
        if row['SECONDARY_SOURCE'] =~ /Jordanus/
          source = jordanus

          # If these catalog fields are filled out, retain that info
          # in the other_info field otherwise it'll get lost. This
          # means we will end up migrating Sources with no records
          # (whatever was in CAT_TBL_ID originally), but that's the
          # best we can do.
          if row['CAT_DATE'].present? || row['CAT_ID'].present? || row['INSTITUTION'].present?
            other_info = append_comment_to_other_info(other_info, "Catalog info for this Jordanus record: #{row['CAT_DATE']} #{row['CAT_ID']} #{row['INSTITUTION']}")
          end

        elsif
          source = unknown_source
          if !deleted
            if row['CAT_DATE'].present? || row['CAT_ID'].present? || row['INSTITUTION'].present?
              create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'no_source_but_has_catalog_info', "entry ID=#{row['MANUSCRIPT_ID']} assigned Unknown source but its catalog fields have data")
            else
              create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'unknown_source', "entry ID=#{row['MANUSCRIPT_ID']} assigned Unknown source because it doesn't have a Catalog entry")
            end
          end
        end
      end

      transaction_type = source.source_type.entries_transaction_field
      if transaction_type == 'choose'
        transaction_type = Entry::TYPE_TRANSACTION_NONE
        if has_sale_information
          transaction_type = (row['SOLD'] == 'GIFT') ? Entry::TYPE_TRANSACTION_GIFT : Entry::TYPE_TRANSACTION_SALE
        end
      end

      # we also record institution in the Source, so if the SourceType
      # doesn't support institution in the entries, it should be okay
      # to skip it.
      institution = nil
      if source.source_type.entries_have_institution_field && row['INSTITUTION'].present?
        institution = get_or_create_agent(row['INSTITUTION'])
      end

      alt_size = ALT_SIZE_CODES_TO_NORMALIZE[row['ALT_SIZE']] || row['ALT_SIZE']
      # there are LOTS of codes with trailing whitespace
      alt_size.strip! if alt_size
      if alt_size.present? && ! VALID_ALT_SIZE_TYPES.member?(alt_size)
        other_info = append_comment_to_other_info(other_info, "'Alt Size' field in the legacy database was '#{alt_size}'")
        alt_size = nil
        # create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'bad_alt_size', "non-normalized value for alt size = '#{row['ALT_SIZE']}'")
      end

      if row['SECONDARY_SOURCE'].present?
        other_info = append_comment_to_other_info(other_info, "'Secondary Source' field in the legacy database was '#{row['SECONDARY_SOURCE']}'")
      end

      # We decided 1/22/15 that we don't need a date field on
      # Entry. We do need to date entries from Sources that don't have
      # a defined date (ex: Ebay, or a constantly changing online
      # catalog), but we can just use the updated_at field if we need
      # to know that.

      entry = Entry.create!(
        id: row['MANUSCRIPT_ID'],
        source: source,
        catalog_or_lot_number: row['CAT_OR_LOT_NUM'],
        institution: institution,
        transaction_type: transaction_type,
        folios: row['FOLIOS'],
        num_columns: row['COL'],
        num_lines: row['NUM_LINES'],
        height: row['HGT'],
        width: row['WDT'],
        alt_size: alt_size,
        manuscript_binding: row['MANUSCRIPT_BINDING'],
        other_info: other_info.present? ? other_info : nil,
        # if the source is electronic, manuscript_link probably is a
        # link to the catalog entry itself, or to a digitial version
        # of the MS. so this link should stay here and not move to
        # Manuscripts table.
        manuscript_link: row['MANUSCRIPT_LINK'],
        miniatures_fullpage: row['MIN_FL'],
        miniatures_large: row['MIN_LG'],
        miniatures_small: row['MIN_SM'],
        miniatures_unspec_size: row['MIN_UN'],
        initials_historiated: row['H_INIT'],
        initials_decorated: row['D_INIT'],
        created_at: row['ADDEDON'],
        created_by: get_or_create_user(row['ADDEDBY']),
        updated_at: row['LAST_MODIFIED'],
        updated_by: get_or_create_user(row['LAST_MODIFIED_BY']),
        approved: approved,
        deleted: deleted,
        unverified_legacy_record: true,
      )

      if row['ENTRY_COMMENTS'].present?
        EntryComment.create!(
          entry: entry,
          comment_attributes: {
            comment: row['ENTRY_COMMENTS'],
            created_at: row['LAST_MODIFIED'] || row['ADDEDON'],
            # we don't know who made the comment (it's possibly been
            # edited by several people), so set it to
            # manuscript_database
            created_by_id: get_or_create_user('manuscript_database').id,
          }
        )
      end

      if has_sale_information

        if institution.present?
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'transaction_institution_conflict', "entry ID=#{row['MANUSCRIPT_ID']} has both institution and transaction fields populated, which isn't allowed")
        end

        # Make sure it makes sense for a Transaction to exist, given the
        # transaction_type
        if !deleted && transaction_type == Entry::TYPE_TRANSACTION_NONE
          populated = sale_fields.select { |field| row[field].present? }.join(", ")
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'transaction', "entry ID=#{row['MANUSCRIPT_ID']} has transaction fields #{populated} populated, but the transaction_type is NONE")
        end

        # although UI for legacy SDBM has an Other Currency field, it
        # was shoving the data into CURRENCY instead of a separate
        # field (I don't know what happens in the legacy SDBM if you
        # fill in both Currency and Other Currency form fields!). Here
        # we treat 'currency' as always normalized and store
        # everything else into a new 'other_currency' field.
        currency = row['CURRENCY']
        other_currency = nil
        if currency.present? && !VALID_CURRENCY_TYPES.member?(currency)
          other_currency = currency
          currency = nil
        end

        # the ALT_DATE field in MANUSCRIPT_CATALOG was used to
        # indicate the actual transaction date, if any, which can be
        # different from the date of the catalog. So we use that here,
        # if we have it, otherwise we leave the date blank.
        start_date = nil
        if (catalog_row = db.query("""select ALT_CAT_DATE from MANUSCRIPT_CATALOG where MANUSCRIPTCATALOGID = #{source.id}""").first)
          start_date = catalog_row['ALT_CAT_DATE'] if catalog_row['ALT_CAT_DATE'].present?
        end

        sold = LEGACY_SOLD_CODES[row['SOLD']] || row['SOLD']
        if sold.present?
          if sold == 'GIFT'
            # gifts are now represented in Entry.transaction_type field
            sold = nil
          elsif sold == 'NF'
            entry.other_info = append_comment_to_other_info(entry.other_info, "'Sold' field in the legacy database had unknown code: '#{sold}'")
            entry.save!
            sold = nil
          else
            if !VALID_SOLD_TYPES.member?(sold)
              create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'sold', "entry ID=#{row['MANUSCRIPT_ID']} had invalid value for Sold field: #{row['SOLD']}")
              sold = nil
            end
          end
        else
          sold = nil
        end

        sale = Sale.create!(
          entry: entry,
          date: start_date,
          price: row['PRICE'],
          currency: currency,
          other_currency: other_currency,
          sold: sold,
        )

        if row['SELLER'].present?
          agent_name, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(row['SELLER'])
          sa = SaleAgent.create!(
            sale: sale,
            agent: get_or_create_agent(agent_name),
            role: SaleAgent::ROLE_SELLING_AGENT,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end

        if row['SELLER2'].present?
          agent_name, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(row['SELLER2'])
          sa = SaleAgent.create!(
            sale: sale,
            agent: get_or_create_agent(agent_name),
            role: SaleAgent::ROLE_SELLER_OR_HOLDER,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end

        if row['BUYER'].present?
          agent_name, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(row['BUYER'])
          sa = SaleAgent.create!(
            sale: sale,
            agent: get_or_create_agent(agent_name),
            role: SaleAgent::ROLE_BUYER,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end
      end

      SDBMSS::Util.split_and_strip(row['TITLE']).each do |atom|
        # this will match [] at ends of string
        title, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(atom)

        title, common_title = parse_common_title(title)

        if title.present? || common_title.present?
          et = EntryTitle.create!(
            entry: entry,
            title: title,
            common_title: common_title,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end
      end

      # there are 38 rows in db that use , instead of | for some of the delimiters
      dates = SDBMSS::Util.split_and_strip(row['MANUSCRIPT_DATE'], delimiter: /[\,\|]/, filter_blanks: false)
      circas = SDBMSS::Util.split_and_strip(row['CIRCA'], delimiter: /[\,\|]/, filter_blanks: false)
      if dates.length != circas.length
        create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'circas_mismatch', "number of dates doesn't match num of circas")
      else
        dates.each_index do |date_index|
          # there DOES exist trailing whitespace in circa values
          date = dates[date_index].strip
          circa = circas[date_index].strip

          # Lots of records have date == '0'. This might actually be meaningful as a year.
          if (date && date.length > 0) || (circa && circa.length > 0)

            date_normalized_start, date_normalized_end, uncertain_in_source, supplied_by_data_entry = normalize_circa_and_date(row['MANUSCRIPT_ID'], circa, date)

            ed = EntryDate.create!(
              entry: entry,
              observed_date: (circa.present? ? circa + " " : "") + date,
              date_normalized_start: date_normalized_start,
              date_normalized_end: date_normalized_end,
              uncertain_in_source: uncertain_in_source,
              supplied_by_data_entry: supplied_by_data_entry,
            )
          end
        end
      end

      authors = SDBMSS::Util.split_and_strip(row['AUTHOR_AUTHORITY'], filter_blanks: false)
      author_variants = SDBMSS::Util.split_and_strip(row['AUTHOR_VARIANT'], filter_blanks: false)
      if authors.length != author_variants.length
        create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'num_author_variants', "Number of author variants doesn't match num of authors in entry")
      end
      authors.each_index do |author_index|

        # we create an EntryAuthor record for each role. Multiple
        # roles exist in the legacy database in diff ways: sometimes
        # there's already an author record per role; sometimes,
        # multiple role codes have been glommed onto an author's name
        # (ex: "Jeff (Tr) (Ed)")

        atom, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(authors[author_index])

        author_str, author_roles = split_author_role_codes(atom)

        if author_roles.length > 1 && author_roles.include?("Attr")
          # this shouldn't happen because in new system, we currently treat 'Attr' as meaning 'Attributed as Author'
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'author_role_conflict', "Author name '#{author_str}' is marked as Attr and ALSO another code!")
        end

        author_variant, author_variant_roles = split_author_role_codes(author_variants[author_index] || "")

        # if there are codes for both, they better match, or there's
        # gonna be trouble (if there are codes for only one of these
        # fields, we don't need to check)
        if author_roles.count > 0 && author_variant_roles.count > 0 && author_roles != author_variant_roles
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'author_role_mismatch', "Role codes in AUTHOR_AUTHORITY and AUTHOR_VARIANT don't match: '#{authors[author_index]}' and '#{author_variants[author_index]}'")
        end

        if author_str.gsub("(").count > 1
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'author_parens', "More than one set of parens found in AUTHOR_AUTHORITY: #{authors[author_index]}")
        end

        if author_str.present? || author_variant.present?
          bad_author = false

          author = nil
          if author_str.present?
            author = get_author(author_str)
            # there are ~50 records where this occurs.
            bad_author = true if author.nil?
          end

          if author_variant == author_str
            # variant is the same, so don't store it.
            author_variant = nil
          elsif author_variant.present?
            if author_variant.length > 255
              create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'author_variant_too_long', "Author variant too long for entry #{row['MANUSCRIPT_ID']} = #{author_variant}")
              author_variant = author_variant[0..254]
            end
          else
            # use NULLs instead of blank strs
            author_variant = nil
          end

          # If we found a non-matching name in Author field,
          # try to use it as the author_variant name instead if nothing's there yet.
          if bad_author
            if author_variant.nil?
              author_variant = author_str
            else
              create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'invalid_author_authority', "'#{author_str}' in AUTHOR_AUTHORITY field not found in Authors lookup table; I'd move it to AUTHOR_VARIANT but something's there already.")
            end
          end

          # If there's a variant but no author, try finding an Author for it
          if author_variant.present? && author.blank?
            author = get_author(author_variant)
            author_variant = nil if author.present?
          end

          # if there are no role codes, stick in a nil role code
          all_roles = Set.new(author_roles + author_variant_roles)
          if all_roles.blank?
            all_roles = Set.new([nil])
          end

          all_roles.each do |author_role|
            # don't create duplicate EntryAuthor records: these exist
            # because legacy data sometimes repeats Authors in an
            # attempt to align them with Titles
            if EntryAuthor.where(entry: entry, observed_name: author_variant, author: author, role: author_role).count == 0
              entry_author = EntryAuthor.create!(
                entry: entry,
                observed_name: author_variant,
                author: author,
                role: author_role,
                uncertain_in_source: uncertain_in_source,
                supplied_by_data_entry: supplied_by_data_entry,
              )
            end
          end
        end
      end

      SDBMSS::Util.split_and_strip(row['ARTIST']).each do |atom|
        name, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(atom)

        if name.present?
          if name =~ /workshop/i || name =~ /style/i || name =~ /artist/i || name =~ /school/i || name =~ /group/i
            observed_name = name
            artist = nil
          else
            observed_name = nil
            artist = get_or_create_artist(name)
          end

          ea = EntryArtist.create!(
            entry: entry,
            artist: artist,
            observed_name: observed_name,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end
      end

      SDBMSS::Util.split_and_strip(row['SCRIBE']).each do |atom|
        name, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(atom)

        if name.present?
          if name =~ /scribe/i
            observed_name = name
            scribe = nil
          else
            observed_name = nil
            scribe = get_or_create_scribe(name)
          end

          es = EntryScribe.create!(
            entry: entry,
            scribe: scribe,
            observed_name: observed_name,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end
      end

      SDBMSS::Util.split_and_strip(row['PROVENANCE']).each do |atom|
        if atom.length < 255
          agent_name, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(atom)

          if agent_name.present?
            # store names as 'observed_name' and then turn non-unique
            # ones into Agent entities at a later pass
            Provenance.create!(
              entry: entry,
              observed_name: agent_name,
              uncertain_in_source: uncertain_in_source,
              supplied_by_data_entry: supplied_by_data_entry
            )
          end
        else
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], "provenance_too_long", "didn't migrate provenance name '#{atom}' because it's too long")
        end
      end

      SDBMSS::Util.split_and_strip(row['LNG']).each do |atom|
        validate_language(atom, row)

        language_str, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(atom)

        if language_str.present?
          language = get_or_create_language(language_str)
          entry_language = EntryLanguage.create!(
            entry: entry,
            language: language,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end
      end

      SDBMSS::Util.split_and_strip(row['MAT']).each do |atom|

        material_str, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(atom)

        material_str = 'P' if material_str == 'Paper'

        material = LEGACY_MATERIAL_CODES[material_str] || LEGACY_MATERIAL_CODES[material_str.upcase] || material_str

        # there exists at least one record whose value is just '?'
        if material.present?
          if !VALID_MATERIALS.member?(material)
            # cleaned up materials on 1/11/2015, so there shouldn't be too many of these left
            create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'invalid_material', "Material '#{material_str}' is not valid")
          end
          em = EntryMaterial.create!(
            entry: entry,
            material: material,
            uncertain_in_source: uncertain_in_source,
            supplied_by_data_entry: supplied_by_data_entry,
          )
        end
      end

      SDBMSS::Util.split_and_strip(row['PLACE']).each do |atom|

        place_str, uncertain_in_source, supplied_by_data_entry = parse_certainty_indicators(atom)

        place = get_or_create_place(place_str)
        EntryPlace.create!(
          entry: entry,
          place: place,
          uncertain_in_source: uncertain_in_source,
          supplied_by_data_entry: supplied_by_data_entry,
        )
      end

      SDBMSS::Util.split_and_strip(row['MANUSCRIPT_USE']).each do |atom|
        eu = EntryUse.create!(
          entry: entry,
          use: atom,
        )
      end

      entry
    end

    def create_agent_entities_for_provenance(legacy_db)
      puts "Creating Agents for non-unique values in Provenance.observed_name"

      # We do this in order to 'conservatively' create Agent records:
      # we only make Agents for Provenance if the agent name occurs
      # more than once. This is actually a pretty good heuristic.

      results = ActiveRecord::Base.connection.execute("SELECT distinct observed_name, count(*) as mynum from provenance where observed_name is not null and length(observed_name) > 1 group by observed_name")

      results.each do |row|
        observed_name, count = row[0], row[1]
        if count > 1
          agent = get_or_create_agent(observed_name)
          Provenance.where(observed_name: observed_name).find_each(batch_size: 200) do |p|
            p.provenance_agent = agent
            p.save!
          end
        end
      end

      puts "Clearing Provenance.observed_name if there's an agent"

      Provenance.where("provenance_agent_id is not null").update_all({ observed_name: nil })

    end

    def create_author_from_row_pass1(row, ctx)
      # ignore AUTHOR_COUNT column since its redundant in new db.
      # there are 'dupes' because of collation rules.

      # flags were stored in Author table; discard them
      author_str, _, _ = parse_certainty_indicators(row['AUTHOR'])
      # discard the role part when migrating authors
      author_name, _ = split_author_role_codes(author_str)

      # there are a few records in this table that have Attr combined
      # with other codes, but we do NOT log an author_role_conflict in
      # the legacy_data_issues b/c this is just a lookup table.

      get_or_create_author(
        author_name,
        extra_attrs:
          {
          reviewed: row['ISAPPROVED'] == 'y',
          reviewed_by: get_or_create_user(row['APPROVEDBY']),
          reviewed_at: row['APPROVEDDATE'],
          }
      )
    end

    def create_author_from_row_pass2(row, ctx)
      if row['MANUSCRIPT_ID'].present?
        entry = nil
        begin
          entry = Entry.find row['MANUSCRIPT_ID']
        rescue ActiveRecord::RecordNotFound => e
          # data loss, but this doesn't seem important
          puts "Author #{row['MANUSCRIPTAUTHORID']} has bad manuscript FK id=#{row['MANUSCRIPT_ID']}, so skipping it."
        end
        if !entry.nil?
          Name.where(id: row['MANUSCRIPTAUTHORID']).update_all({ entry_id: entry.id })
        end
      end
    end

    def create_artist_from_row_pass1(row, ctx)
      # flags were stored in Artist table; discard them
      artist_str, _, _ = parse_certainty_indicators(row['ARTIST'])

      get_or_create_artist(
        artist_str,
        extra_attrs:
          {
            reviewed: row['ISAPPROVED'] == 'y',
            reviewed_by: get_or_create_user(row['APPROVEDBY']),
            reviewed_at: row['APPROVEDDATE'],
          }
      )
    end

    # 2nd pass after creation of Entry objects, so we can set the FK
    def create_artist_from_row_pass2(row, ctx)
      if row['MANUSCRIPT_ID'].present?
        entry = nil
        begin
          entry = Entry.find row['MANUSCRIPT_ID']
        rescue ActiveRecord::RecordNotFound => e
          # data loss, but this doesn't seem important
          puts "Artist #{row['MANUSCRIPTARTISTID']} has bad manuscript FK id=#{row['MANUSCRIPT_ID']}, so skipping it."
        end

        if !entry.nil?
          Name.where(id: row['MANUSCRIPTARTISTID']).update_all({ entry_id: entry.id })
        end
      end
    end

    def create_source_from_row(row, ctx)
      date = row['CAT_DATE']
      if date == '00000000'
        date = nil
      elsif !date.nil? && ![4, 6, 8].member?(date.length) && row['ISDELETED'] != 'y'
        create_issue('MANUSCRIPT_CATALOG', row['MANUSCRIPTCATALOGID'], "bad_date", "bad date #{date}: should be either YYYY, YYYYMM or YYYYMMDD")
      end

      seller = nil
      if row['SELLER'].present?
        seller = get_or_create_agent(row['SELLER'])
      end

      institution = nil
      if row['INSTITUTION'].present?
        institution = get_or_create_agent(row['INSTITUTION'])
      end

      in_manuscript_table = row['IN_MANUSCRIPT_TBL'] == 'y'

      deleted = row['ISDELETED'] == 'y'

      hidden = row['HIDDEN_CAT'] == 'y'

      # Determine the SourceType and null out irrelevant fields; this
      # means we will lose some data. but since these fields are
      # duplicated in Manuscript, they should get migrated there and
      # it should be fine. I think.
      source_type = nil
      case
      when row['SELLER'].present?
        source_type = SourceType.auction_catalog
        institution = nil
      when row['INSTITUTION'].present?
        source_type = SourceType.collection_catalog
        seller = nil
      else
        source_type = SourceType.other_published
      end

      author = row['CAT_AUTHOR']

      whether_mss = row['WHETHER_MSS']
      if ['Likely', 'Not Likely', 'Uncertain'].member? whether_mss
        whether_mss = 'Maybe'
      end

      status = row['SDBM_STATUS']
      if status == 'Not Entered (No MSS)'
        if whether_mss.present?
          if whether_mss != 'No'
            if !deleted
              create_issue('MANUSCRIPT_CATALOG', row['MANUSCRIPTCATALOGID'], "bad_status", "catalog SDBM_STATUS is #{row['SDBM_STATUS']} but WHETHER_MSS is #{row['WHETHER_MSS']}, which makes no sense")
            end
          end
        else
          whether_mss = 'No'
        end
      end
      if (!status.present?) || status == 'To Be Checked'
        status = 'To Be Entered'
      end

      medium = nil
      if row['ONLINE_LINK'].present? && (row['ONLINE_LINK'].include?("www") || row['ONLINE_LINK'].include?("http"))
        medium = Source::TYPE_MEDIUM_INTERNET;
      end

      comments = row['COMMENTS']

      # NOTE: there do exist Catalogs with no Entries, and that's
      # ok. these can indicate that someone looked at a catalog and
      # determined that there are no MSS relevant for SDBM (the
      # "whether_mss" field). It is meaningful to know that, so don't
      # delete them.

      # we don't import:
      # MS_COUNT = this is now redundant since we're using FKs
      # ALT_DATE = this has moved into Sale.date on transaction records

      source = Source.new(
        id: row['MANUSCRIPTCATALOGID'],
        source_type: source_type,
        date: date,
        title: row['CAT_ID'],
        author: author,
        whether_mss: whether_mss,
        location_institution: row['CURRENT_LOCATION'],
        location: [row['LOCATION_CITY'], row['LOCATION_COUNTRY']].select { |s| s.present? }.join(",") || nil,
        link: row['ONLINE_LINK'],
        medium: medium,
        in_manuscript_table: in_manuscript_table,
        deleted: deleted,
        created_at: row['ADDED_ON'],
        created_by: get_or_create_user(row['ADDED_BY']),
        updated_at: row['LAST_MODIFIED'],
        updated_by: get_or_create_user(row['LAST_MODIFIED_BY']),
        comments: comments,
        status: status,
        hidden: hidden,
      )

      # move values in invalid fields to comments field
      source.invalid_source_fields.each do |field|
        value = source.send(field.to_sym)
        if value.present?
          source.comments = source.comments.present? ? source.comments + "\n" : ""
          source.comments += "'#{field}' field with value '#{value}' in the legacy database could not be migrated into an appropriate field for this source type"
          source.send((field + "=").to_sym, nil)
        end
      end

      source.save!

      if institution
        SourceAgent.create!(
          source: source,
          agent: institution,
          role: SourceAgent::ROLE_INSTITUTION,
        )
      end

      if seller
        SourceAgent.create!(
          source: source,
          agent: seller,
          role: SourceAgent::ROLE_SELLING_AGENT,
        )
      end

      SOURCE_CACHE[source.id] = source

    end

    def create_place_from_row_pass1(row, ctx)
      # flags were stored in Place table; discard them
      place_str, _, _ = parse_certainty_indicators(row['PLACE'])

      # we ignore PLACE_COUNT b/c it's redundant now

      # there do exist a few dupes. sigh.
      if !Place.where(name: place_str).order(nil).first.nil?
        Place.create!(
          id: row['MANUSCRIPTPLACEID'],
          name: place_str,
          reviewed: row['ISAPPROVED'] == 'y',
          reviewed_by: get_or_create_user(row['APPROVEDBY']),
          reviewed_at: row['APPROVEDDATE'],
        )
      end
    end

    # 2nd pass after creation of Entry objects, so we can set the FK
    def create_place_from_row_pass2(row, ctx)
      if row['MANUSCRIPT_ID'].present?
        entry = nil
        begin
          entry = Entry.find row['MANUSCRIPT_ID']
        rescue ActiveRecord::RecordNotFound => e
          # data loss, but this doesn't seem important
          puts "Place #{row['MANUSCRIPTPLACEID']} has bad manuscript FK id=#{row['MANUSCRIPT_ID']}, so skipping it."
        end
        if !entry.nil?
          Place.where(id: row['MANUSCRIPTPLACEID']).update_all({ entry_id: entry.id })
        end
      end
    end

    def create_manuscript_changelog_from_row(row, ctx)
      if row['MANUSCRIPTID'].present? && Entry.exists?(row['MANUSCRIPTID'])
        EntryChange.create!(
          entry_id: row['MANUSCRIPTID'],
          column: row['CHANGEDCOLUMN'],
          changed_from: row['CHANGEDFROM'],
          changed_to: row['CHANGEDTO'],
          change_type: row['CHANGETYPE'],
          change_date: row['CHANGEDATE'],
          changed_by: get_or_create_user(row['CHANGEDBY']),
        )
      end
    end

    def create_manuscripts_from_duplicates(duplicates)

      duplicates.each do |duplicate_list_str|
        manuscript = nil

        SDBMSS::Util.split_and_strip(duplicate_list_str, delimiter: ",").each do |atom|
          relation_type = EntryManuscript::TYPE_RELATION_IS
          if atom.include? 'X'
            atom = atom.sub("X", '')
            relation_type = EntryManuscript::TYPE_RELATION_PARTIAL
          end

          entry = nil
          begin
            entry = Entry.find atom.to_i
          rescue
            puts "WARNING: id found in DUPLICATE_MS doesn't exist: #{atom}, not creating an EntryManuscript record for it"
          end

          if entry
            if manuscript.nil?
              em = EntryManuscript.where(entry: entry).order(nil).first
              manuscript = em.manuscript if em
              manuscript = Manuscript.create!() if manuscript.nil?
            end

            if EntryManuscript.where(entry: entry, relation_type: EntryManuscript::TYPE_RELATION_IS).count > 0
              create_issue('MANUSCRIPT', entry.id, "multiple_manuscripts", "Warning: entry ID = #{entry.id} was assigned to more than one Manuscript")
            end

            manuscript_entry = EntryManuscript.create!(
              entry: entry,
              manuscript: manuscript,
              relation_type: relation_type,
            )
          end

        end

      end

    end

    def create_entry_manuscripts_from_possible_dups(row, ctx)
      SDBMSS::Util.split_and_strip(row['POSSIBLE_DUPS'], delimiter: ",").each do |possible_dupe|
        # find or create the MS for the possible dupe Entry
        if possible_dupe.present? && Entry.exists?(possible_dupe)

          em = EntryManuscript.where(entry_id: possible_dupe, relation_type: EntryManuscript::TYPE_RELATION_IS).first
          manuscript_id = nil
          if em
            manuscript_id = em.manuscript_id
          else
            # These manuscripts will only have one 'confirmed'
            # entry, which is annoying, and possibly even bad, but we
            # need it to connect 2 Entries that potentially represent
            # the same MS
            puts "Warning: creating a Manuscript record for an entry #{possible_dupe} found in POSSIBLE_DUPS that doesn't yet have one"
            manuscript = Manuscript.create!()

            manuscript_entry = EntryManuscript.create!(
              entry_id: possible_dupe,
              manuscript_id: manuscript.id,
              relation_type: EntryManuscript::TYPE_RELATION_IS,
            )

            manuscript_id = manuscript.id
          end

          already_linked = EntryManuscript.where(
            entry_id: row['MANUSCRIPT_ID'],
            manuscript_id: manuscript_id,
            relation_type: EntryManuscript::TYPE_RELATION_POSSIBLE,
          ).count > 0

          if !already_linked
            EntryManuscript.create!(
              entry_id: row['MANUSCRIPT_ID'],
              manuscript_id: manuscript_id,
              relation_type: EntryManuscript::TYPE_RELATION_POSSIBLE,
            )
          end
        else
          puts "Warning: entry #{row['MANUSCRIPT_ID']} has id #{possible_dupe} in POSSIBLE_DUPS field, which doesn't exist"
        end
      end

    end

  end # end module-level methods

end
