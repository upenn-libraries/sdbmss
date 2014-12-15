#
# XXX: tweak models/migrations
#
# change column names for 'added_on' and 'last_modified' to conform to Rails conventions? use t.timestamps in migration scripts
#
# figure out indexes, constraints, FKs, default values (esp for booleans); and how to add them

require 'date'
require 'set'

# Code pertaining to the legacy Oracle database, that's been copied
# into MySQL for ease of handling.
module SDBMSS::Legacy

  # module-level methods
  class << self

    # XXX: from django
    VALID_ALT_SIZE_TYPES = Entry::ALT_SIZE_TYPES.map { |item| item[0] }

    # XXX: from django
    VALID_CIRCA_TYPES = EntryDate::CIRCA_TYPES.map { |item| item[0] }

    # XXX: from django
    VALID_CURRENCY_TYPES = Event::CURRENCY_TYPES.map { |item| item[0] }

    # XXX: from django
    VALID_MATERIALS = EntryMaterial::MATERIAL_TYPES.map { |item| item[0] }

    REGEX_COMMON_TITLE = /\[(.+)\]/

    # Returns db connection to the legacy database in MySQL.
    def get_legacy_db_conn
      Mysql2::Client.new(:host => "localhost", :username => "root", :database => 'sdbm_live_copy')
    end

    def create_user(row, ctx)
      password = row['PENNKEYPASS']
      # pw must be at least 8 chars
      if password.length < 8
        password = 'somethingunguessable'
      end
      user = User.sdbm_create!(username: row['PENNKEY'],
                          email: row['PENNKEY'] + "@upenn.edu",
                          password: password)
      # XXX: implement perm groups
      # case
      # when row['PERMISSION'] == 'entry'
      #   user.groups.add(Group.objects.get(name='Staff'))
      # when row['PERMISSION'] == 'edit'
      #   user.groups.add(Group.objects.get(name='Editor'))
      # when row['PERMISSION'] == 'admin'
      #   user.groups.add(Group.objects.get(name='Administrator'))
      # end
    end

    USER_CACHE = {}

    def get_or_create_user(username)
      if username
        if ! USER_CACHE.member?(username)
          user = User.where(username: username).first
          if user.nil?
            user = User.sdbm_create!(
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

    AGENT_CACHE = {}

    def get_or_create_agent(name)
      if name
        if ! AGENT_CACHE.member?(name)
          agent = Agent.where(name: name).order(nil).first
          if agent.nil?
            agent = Agent.sdbm_create!(name: name, agent_type: 'unknown', approved: true)
          end
          AGENT_CACHE[name] = agent
        end
      end
      AGENT_CACHE[name]
    end

    AUTHOR_CACHE = {}

    def get_author(name)
      AUTHOR_CACHE[name]
    end

    SOURCE_CACHE = {}

    def get_source(id)
      SOURCE_CACHE[id]
    end

    # Do the migration
    def migrate(fast: false)

      # add method ActiveRecord::Base#sdbm_create! which delegates to
      # either create! or import based on 'fast' flag
      if fast
        puts "WARNING: Using fast mode"
        p = Proc.new { |**opts|
          obj = new(**opts)
          import [ obj ], :validate => false
          obj
        }
      else
        p = Proc.new { |**opts|
          create!(**opts)
        }
      end
      ActiveRecord::Base.class.send(:define_method, :sdbm_create!, p)

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

      # XXX: implement perm groups
      # for group_name in ('Regular User', 'Staff', 'Editor', 'Administrator'):
      #     Group.objects.create(name=group_name)

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
      unknown_source = Source.sdbm_create!(
        date: "00000000",
        title: "Unknown (entry record needs to be fixed)"
      )

      # special case for handling records from Jordanus
      jordanus = Source.sdbm_create!(
        date: "00000000",
        title: "Jordanus",
      )

      puts "Migrating Source records"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_CATALOG ORDER BY MANUSCRIPTCATALOGID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_source_from_row(row, ctx)
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
                         ctx: {duplicates: duplicates, unknown_source: unknown_source, jordanus: jordanus},
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_entry_from_row(row, ctx)
      end

      puts "Creating Agent entities for non-unique names in EventAgent"

      create_agent_entities_for_provenance(legacy_db)

      puts "Second pass over Author records"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_AUTHOR ORDER BY MANUSCRIPTAUTHORID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_author_from_row_pass2(row, ctx)
      end

      puts "Second pass over Artist records"

      SDBMSS::Util.batch(legacy_db,
                         'SELECT * FROM MANUSCRIPT_ARTIST ORDER BY MANUSCRIPTARTISTID',
                         batch_wrapper: wrap_transaction) do |row,ctx|
        create_artist_from_row_pass2(row, ctx)
      end

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
        MANUSCRIPT.ISDELETED != 'y'
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
        and MANUSCRIPT.ISDELETED != 'y'
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
      LegacyDataIssue.sdbm_create!(
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
        entry = create_entry_and_all_associations(row, ctx[:unknown_source], ctx[:jordanus])
      rescue Exception => e
        puts "error on id=#{row['MANUSCRIPT_ID']}"
        raise
      end

      if row['DUPLICATE_MS'].present?
        duplicates.add(row['DUPLICATE_MS'])
      end

      # TODO: handle "possible_dups"
    end

    def create_entry_and_all_associations(row, unknown_source, jordanus)

      date = row['CAT_DATE']
      date = nil if date == '00000000'

      validate_fuzzy_date(date, row)

      # we regard Nulls as meaning approved, since thats how they seem
      # to be treated.
      approved = row['ISAPPROVED'] != 'n'

      deleted = row['ISDELETED'] == 'y'

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
        # about 9000 Manuscript records with Jordanus as
        # SECONDARY_SOURCE have CAT_TBL_ID = null
        if row['SECONDARY_SOURCE'] == 'Jordanus'
          source = jordanus
        elsif
          source = unknown_source
          create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'unknown_source', "entry ID=#{row['MANUSCRIPT_ID']} assigned Unknown source because it doesn't have a Catalog entry")
        end
      end

      if row['ALT_SIZE'].present? and ! VALID_ALT_SIZE_TYPES.member? row['ALT_SIZE']
        # TODO: these can be cleaned up programmatically, no need to warn
        # print "WARNING: entry ID=%s has bad alt_size value: %s" % (row['MANUSCRIPT_ID'], row['ALT_SIZE'])
      end

      # this is faster than manual begin/commit: why?
      entry = Entry.sdbm_create!(
        id: row['MANUSCRIPT_ID'],
        source: source,
        catalog_or_lot_number: row['CAT_OR_LOT_NUM'],
        secondary_source: row['SECONDARY_SOURCE'],
        current_location: row['CURRENT_LOCATION'],
        folios: row['FOLIOS'],
        num_columns: row['COL'],
        num_lines: row['NUM_LINES'],
        height: row['HGT'],
        width: row['WDT'],
        alt_size: row['ALT_SIZE'],
        manuscript_binding: row['MANUSCRIPT_BINDING'],
        other_info: row['COMMENTS'],
        # TODO: move to MS?
        manuscript_link: row['MANUSCRIPT_LINK'],
        miniatures_fullpage: row['MIN_FL'],
        miniatures_large: row['MIN_LG'],
        miniatures_small: row['MIN_SM'],
        miniatures_unspec_size: row['MIN_UN'],
        initials_historiated: row['H_INIT'],
        initials_decorated: row['D_INIT'],
        # XXX: handle timezones?
        added_on: row['ADDEDON'],
        added_by: get_or_create_user(row['ADDEDBY']),
        approved: approved,
        deleted: deleted,
        last_modified: row['LAST_MODIFIED'],
        last_modified_by: get_or_create_user(row['LAST_MODIFIED_BY']),
      )

      if row['ENTRY_COMMENTS'].present?
        EntryComment.sdbm_create!(
          entry: entry,
          comment: row['ENTRY_COMMENTS'],
          public: false,
          # we don't know who made the comment (it's possibly been
          # edited by several people), so set it to
          # manuscript_database
          added_by: get_or_create_user('manuscript_database'),
          )
      end

      # there are a lot of records (as many as 1500?) with only Buyer
      # field filled in for entries in a collection catalog, and Buyer
      # more or less matches Institution/Collection. In these cases, I
      # think we can ignore Buyer and skip creation of sale record
      if row['BUYER'].present? &&
         row['INSTITUTION'].present? &&
         !(row['SELLER'].present? ||
           row['SELLER2'].present? ||
           row['PRICE'].present? ||
           row['CURRENCY'].present? ||
           row['SOLD'].present?)
        puts "WARNING: record #{row['MANUSCRIPT_ID']}: ignoring 'buyer' field since it's the only sale-related field populated, and there's a value in INSTITUTION, so I'm not creating a sale record."
      elsif row['SELLER'].present? ||
            row['SELLER2'].present? ||
            row['BUYER'].present? ||
            row['PRICE'].present? ||
            row['CURRENCY'].present? ||
            row['SOLD'].present?

        # although UI for legacy SDBM has an Other Currency field, it
        # was shoving the data into CURRENCY instead of a separate
        # field. We treat 'currency' as always normalized and store
        # everything else into a new 'other_currency' field.
        currency = row['CURRENCY']
        other_currency = nil
        if currency.present? && !VALID_CURRENCY_TYPES.member?(currency)
          other_currency = currency
          currency = nil
        end

        # we suppress Sale info on UI for some source types, so make
        # sure non-sale sources don't have sale info
        if source.source_type == 'collection_catalog' && row['SECONDARY_SOURCE'].blank?
          # this is probably a child record?
          puts "ERROR: record #{row['MANUSCRIPT_ID']}: has 'collection_catalog' source and no secondary source, therefore it should not have sale info"
        end

        sale = Event.sdbm_create!(
          primary: true,
          entry: entry,
          acquire_date: row['CAT_DATE'],
          price: row['PRICE'],
          currency: currency,
          other_currency: other_currency,
          sold: row['SOLD'],
        )

        if row['SELLER'].present?
          pa = EventAgent.sdbm_create!(
            event: sale,
            agent: get_or_create_agent(row['SELLER']),
            role: EventAgent::ROLE_SELLER_AGENT,
          )
        end

        if row['SELLER2'].present?
          pa = EventAgent.sdbm_create!(
            event: sale,
            agent: get_or_create_agent(row['SELLER2']),
            role: EventAgent::ROLE_SELLER_OR_HOLDER,
          )
        end

        if row['BUYER'].present?
          pa = EventAgent.sdbm_create!(
            event: sale,
            agent: get_or_create_agent(row['BUYER']),
            role: EventAgent::ROLE_BUYER,
          )
        end
      end

      SDBMSS::Util.split_and_strip(row['TITLE']).each do |atom|
        title = atom
        common_title = nil

        # TODO: needs tweaking, to be safe, we should probably only
        # match [] at end of string
        if match = REGEX_COMMON_TITLE.match(title)
          common_title = match[1]
          title = title[0..match.begin(0)-1] + title[match.end(0)..-1]
          title = title.strip()
        end

        et = EntryTitle.sdbm_create!(
          entry: entry,
          title: title,
          common_title: common_title,
          )
      end

      # there are 38 rows in db that use , instead of | for some of the delimiters
      dates = SDBMSS::Util.split_and_strip(row['MANUSCRIPT_DATE'], delimiter: /[\,\|]/, filter_blanks: false)
      circas = SDBMSS::Util.split_and_strip(row['CIRCA'], delimiter: /[\,\|]/, filter_blanks: false)
      # TODO: do NOT skip dates if they don't match, fix the damn data
      if dates.length != circas.length
        create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'circas_mismatch', "number of dates doesn't match num of circas")
      else
        dates.each_index do |date_index|
          date = dates[date_index]
          if date
            # TODO: Lots of records have date == '0'. This might actually be meaningful as a year.

            circa = circas[date_index]
            if circa && !VALID_CIRCA_TYPES.member?(circa)
              # TODO: there's too many of these to print out; figure out what they mean
              # print "WARNING: record %s: invalid circa value: %s" % (row['MANUSCRIPT_ID'], circa)
            end

            # TODO: circas are not normalized in DB; their absence
            # in options in UI will cause data loss!
            ed = EntryDate.sdbm_create!(
              entry: entry,
              date: date,
              circa: circa,
            )
          end
        end
      end

      # TODO: deal with roles in author records: ex: "Decembrio, Pier
      # Candido (Tr)" there are roughly 1000 author records like these.
      authors = SDBMSS::Util.split_and_strip(row['AUTHOR_AUTHORITY'], filter_blanks: false)
      author_variants = SDBMSS::Util.split_and_strip(row['AUTHOR_VARIANT'], filter_blanks: false)
      if authors.length != author_variants.length
        puts "Warning: number of author variants doesn't match num of authors in entry #{row['MANUSCRIPT_ID']}"
      end
      authors.each_index do |author_index|
        atom = authors[author_index]
        # TODO: does this skip over AuthorVariant entries that dont have AuthorAuthority entries?
        if atom && atom.length > 0
          bad_author = false
          author = get_author(atom) #Author.where(name: atom).order(nil).first
          # there are ~50 records where this occurs.
          bad_author = true if author.nil?

          author_variant = author_variants[author_index]
          if author_variant.nil?
            puts "Warning: no author variant found for author in entry #{row['MANUSCRIPT_ID']}"
          end

          if author_variant == atom
            # variant is the same, so don't store it.
            author_variant = nil
          elsif author_variant != ""
            if author_variant.length > 255
              puts "Author variant too long for entry #{row['MANUSCRIPT_ID']} = #{author_variant}"
              author_variant = nil
            end
          else
            # use NULLs instead of blank strs
            author_variant = nil
          end

          # TODO: do we really want to do this, or is it actually
          # meaningful to duplicate names across these fields?
          # if author and author.name == author_variant:
          #     print "Found author variant that's exactly the same as author in %s" % (row['MANUSCRIPT_ID'],)
          #     author_variant = None

          # If we found a non-matching name in Author field,
          # try to use it as the author_variant name instead if nothing's there yet.
          if bad_author
            if author_variant.nil?
              author_variant = atom
            else
              create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'invalid_author_authority', "'#{atom}' in AUTHOR_AUTHORITY field not found in Authors lookup table; I'd move it to AUTHOR_VARIANT but something's there already.")
            end
          end

          entry_author = EntryAuthor.sdbm_create!(
            entry: entry,
            observed_name: author_variant,
            author: author,
          )
        end
      end

      SDBMSS::Util.split_and_strip(row['ARTIST']).each do |atom|
        artist = Artist.where(name: atom).order(nil).first_or_create!
        ea = EntryArtist.sdbm_create!(
          entry: entry,
          artist: artist,
          )
      end

      SDBMSS::Util.split_and_strip(row['SCRIBE']).each do |atom|
        scribe = Scribe.where(name: atom).order(nil).first_or_create!
        es = EntryScribe.sdbm_create!(
          entry: entry,
          scribe: scribe,
        )
      end

      SDBMSS::Util.split_and_strip(row['PROVENANCE']).each do |atom|
        # TODO: we should fix the data in the db
        if atom.length < 255
          provenance = Event.sdbm_create!(
            # primary: false,
            entry: entry,
          )

          # store names as 'observed_name' and then turn non-unique
          # ones into Agent entities at a later pass
          pa = EventAgent.sdbm_create!(
            event: provenance,
            observed_name: atom,
            role: EventAgent::ROLE_SELLER_OR_HOLDER,
          )
        else
          puts "WARNING: skipping provenance entry for record #{row['MANUSCRIPT_ID']} because it's too long"
        end
      end

      SDBMSS::Util.split_and_strip(row['LNG']).each do |atom|
        validate_language(atom, row)
        language = get_or_create_language(atom)
        entry_language = EntryLanguage.sdbm_create!(
          entry: entry,
          language: language,
        )
      end

      SDBMSS::Util.split_and_strip(row['MAT']).each do |atom|
        atom = 'P' if atom == 'Paper'
        if !VALID_MATERIALS.member?(atom)
          # too many of these
          # create_issue('MANUSCRIPT', row['MANUSCRIPT_ID'], 'invalid_material', "Material '%s' is not valid" % (atom,))
        end
        em = EntryMaterial.sdbm_create!(
          entry: entry,
          material: atom,
        )
      end

      SDBMSS::Util.split_and_strip(row['PLACE']).each do |atom|
        place = get_or_create_place(atom)
        EntryPlace.sdbm_create!(
          entry: entry,
          place: place,
        )
      end

      SDBMSS::Util.split_and_strip(row['MANUSCRIPT_USE']).each do |atom|
        eu = EntryUse.sdbm_create!(
          entry: entry,
          use: atom,
        )
      end

      entry
    end

    def create_agent_entities_for_provenance(legacy_db)
      puts "Creating Agents for non-unique values in EventAgent.observed_name"

      # We do this in order to 'conservatively' create Agent records:
      # we only make Agents for Provenance if the agent name occurs
      # more than once. This is actually a pretty good heuristic.

      results = ActiveRecord::Base.connection.execute("SELECT distinct observed_name, count(*) as mynum from event_agents where observed_name is not null group by observed_name")

      results.each do |row|
        observed_name, count = row[0], row[1]
        if count > 1
          agent = get_or_create_agent(observed_name)
          EventAgent.where(observed_name: observed_name).update_all({ agent_id: agent.id })
        end
      end

      puts "Clearing EventAgent.observed_name if there's an agent"

      EventAgent.where("agent_id is not null").update_all({ observed_name: nil })

      # TODO: Some very non-unique long provenance strings should be
      # moved to comments. See entry 104980, which has str describing
      # bequeathal.
    end

    def create_author_from_row_pass1(row, ctx)
      # ignore AUTHOR_COUNT column since its redundant in new db.
      # there are 'dupes' because of collation rules.
      author = Author.where(name: row['AUTHOR']).order(nil).first
      if author.nil?
        author = Author.sdbm_create!(
          name: row['AUTHOR'],
          approved: row['ISAPPROVED'] == 'y',
          approved_by: get_or_create_user(row['APPROVEDBY']),
          approved_date: row['APPROVEDDATE'],
        )
        AUTHOR_CACHE[row['AUTHOR']] = author
      end
      author
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
          Author.where(id: row['MANUSCRIPTAUTHORID']).update_all({ entry_id: entry.id })
        end
      end
    end

    def create_artist_from_row_pass1(row, ctx)
      # we ignore ARTIST_COUNT b/c it's redundant now
      Artist.sdbm_create!(
        id: row['MANUSCRIPTARTISTID'],
        name: row['ARTIST'],
        approved: row['ISAPPROVED'] == 'y',
        approved_by: get_or_create_user(row['APPROVEDBY']),
        approved_date: row['APPROVEDDATE'],
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
          Artist.where(id: row['MANUSCRIPTARTISTID']).update_all({ entry_id: entry.id })
        end
      end
    end

    def create_source_from_row(row, ctx)
      date = row['CAT_DATE']
      if date == '00000000'
        date = nil
      elsif !date.nil? && ![4, 6, 8].member?(date.length)
        create_issue('MANUSCRIPT_CATALOG', row['MANUSCRIPTCATALOGID'], "bad_date", "bad date #{date}: should be either YYYY, YYYYMM or YYYYMMDD")
      end

      # TODO: seller2 MIGHT (but not always) indicate that all records
      # for the source were sold by that seller. how do we know when
      # that is the case?

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

      source_type = nil
      case
      when row['SELLER'].present?
        # TODO: assert that other fields are blank?
        source_type = 'auction_catalog'
      when row['INSTITUTION'].present?
        source_type = 'collection_catalog'
      else
        source_type = 'other_published'
      end

      # we don't import:
      # MS_COUNT = this is now redundant since we're using FKs

      source = Source.sdbm_create!(
        id: row['MANUSCRIPTCATALOGID'],
        source_type: source_type,
        date: date,
        title: row['CAT_ID'],
        alt_date: row['ALT_CAT_DATE'],
        author: row['CAT_AUTHOR'],
        whether_mss: row['WHETHER_MSS'],
        current_location: row['CURRENT_LOCATION'],
        location_city: row['LOCATION_CITY'],
        location_country: row['LOCATION_COUNTRY'],
        link: row['ONLINE_LINK'],
        electronic_catalog_format: row['ELEC_CAT_FORMAT'],
        electronic_catalog_open_access: row['ELEC_CAT_OPENACCESS'],
        in_manuscript_table: in_manuscript_table,
        deleted: deleted,
        added_on: row['ADDED_ON'],
        added_by: get_or_create_user(row['ADDED_BY']),
        last_modified: row['LAST_MODIFIED'],
        last_modified_by: get_or_create_user(row['LAST_MODIFIED_BY']),
        comments: row['COMMENTS'],
        cataloging_type: row['CATALOGING_TYPE'],
        status: row['SDBM_STATUS'],
        hidden: hidden,
      )

      if institution
        SourceAgent.sdbm_create!(
          source: source,
          agent: institution,
          role: "institution",
        )
      end

      if seller
        SourceAgent.sdbm_create!(
          source: source,
          agent: seller,
          role: "seller_agent",
        )
      end

      SOURCE_CACHE[source.id] = source

    end

    def create_place_from_row_pass1(row, ctx)
      # we ignore PLACE_COUNT b/c it's redundant now

      # there do exist a few dupes. sigh.
      if !Place.where(name: row['PLACE']).order(nil).first.nil?
        Place.sdbm_create!(
          id: row['MANUSCRIPTPLACEID'],
          name: row['PLACE'],
          approved: row['ISAPPROVED'] == 'y',
          approved_by: row['APPROVEDBY'],
          approved_date: row['APPROVEDDATE'],
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
      EntryChange.sdbm_create!(
        entry_id: row['MANUSCRIPTID'],
        column: row['CHANGEDCOLUMN'],
        changed_from: row['CHANGEDFROM'],
        changed_to: row['CHANGEDTO'],
        change_type: row['CHANGETYPE'],
        change_date: row['CHANGEDATE'],
        changed_by: get_or_create_user(row['CHANGEDBY']),
      )
    end

    def create_manuscripts_from_duplicates(duplicates)

      duplicates.each do |duplicate_list_str|
        manuscript = nil
        manuscript_entries = []

        SDBMSS::Util.split_and_strip(duplicate_list_str, delimiter: ",").each do |atom|
          relation_type = nil
          if atom.include? 'X'
            atom = atom.sub("X", '')
            relation_type = 'partial'
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
              manuscript = Manuscript.sdbm_create!() if manuscript.nil?
            end

            manuscript_entry = EntryManuscript.sdbm_create!(
              entry: entry,
              manuscript: manuscript,
              relation_type: relation_type,
            )
          end

        end

      end

    end

  end # end module-level methods

end
