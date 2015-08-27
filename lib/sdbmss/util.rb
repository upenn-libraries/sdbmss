
require 'csv'
require 'date'
require 'net/http'
require 'uri'

require 'active_support/all'

module SDBMSS

  module Util

    CHECKMARK = "\u2713".encode('utf-8')

    class << self

      # Does a SQL select query in batches, passing each row to the
      # code block
      def batch(conn, sql, ctx: nil, limit: 1000, batch_wrapper: nil, silent: false, &block)
        ctx ||= {}
        ctx.update({:count => 0, :start_time => Time::now.to_f })

        # if no batch_wrapper is passed in, make a default that just
        # calls passed-in process_batch proc
        if batch_wrapper.nil?
          batch_wrapper = Proc.new do |process_batch|
            process_batch.call
          end
        end
        
        keep_going = true
        offset = 0
        while keep_going
          results = conn.query(sql + " LIMIT #{limit} OFFSET #{offset}")
          if results.count > 0

            # Proc closure over local vars
            process_batch = Proc.new do
              results.each do |row|
                block.call row, ctx
                ctx[:count] += 1
              end
            end
            
            batch_wrapper.call(process_batch)
            
            elapsed = Time::now.to_f - ctx[:start_time]
            rate = 0
            if elapsed > 0
              rate = ctx[:count] / elapsed
            end
            puts "Processed #{ctx[:count]} records so far in batch(): overall rate: #{rate} records/sec" unless silent

            offset += limit
          else
            keep_going = false
          end
        end
      end

      # Split a string by delimiter, strip its pieces, and return a list
      # of those pieces
      def split_and_strip(s, delimiter: "|", filter_blanks: true)
        if s && s.length > 0
          pieces = s.split(delimiter).map { |atom| atom.strip }
        else
          # blank str should split into 1 item list
          pieces = [""]
        end
        if filter_blanks
          pieces = pieces.select { |atom| !atom.nil? && atom.length > 0 }
        end
        pieces
      end

      # returns the most recent updated_at timestamp field, as an
      # integer, of the model_object AND all its pertinent
      # associations. This is used as a mechanism to prevent the user
      # from saving changes when another change was made to the data.
      def cumulative_updated_at(model_object, associations)
        most_recent = model_object.updated_at.to_i
        associations.each do |association|
          records = model_object.send(association)
          records.each do |record|
            if record.respond_to?(:updated_at)
              record_updated_at = record.updated_at.to_i
              if record_updated_at > most_recent
                most_recent = record_updated_at
              end
            end
          end
        end
        most_recent || 0
      end

      def update_counter_cache_all
        Rails.application.eager_load!
        ActiveRecord::Base.descendants.each do |many_class|
          update_counter_cache(many_class)
        end
        nil
      end

      # Given a class, updates all the counter_cache fields on it, for
      # all records.
      #
      # This is a modified version of the code found here:
      # https://www.krautcomputing.com/blog/2015/01/13/recalculate-counter-cache-columns-in-rails/
      def update_counter_cache(clazz)
        clazz.reflections.each do |name, reflection|
          if reflection.options[:counter_cache]
            one_class = reflection.class_name.constantize
            one_table, many_table = [one_class, clazz].map(&:table_name)
            count_field_name = reflection.options[:counter_cache] != true ? reflection.options[:counter_cache] : "#{many_table}_count"
            ids = one_class
                  .joins(many_table.to_sym)
                  .group("#{one_table}.id", "#{one_table}.#{count_field_name}")
                  .having("COALESCE(#{one_table}.#{count_field_name}, 0) != COUNT(#{many_table}.id)")
                  .pluck("#{one_table}.id")
            ids.each do |id|
              puts "#{one_class} #{id}"
              one_class.reset_counters id, many_table
            end
          end
        end
        nil
      end

      # returns a reasonably formatted date string based on a YYYYMMDD
      # str value, which may have 0's in it. Resulting string is in one of these formats: YYYY, YYYY-MM, YYYY-MM-DD
      def format_fuzzy_date(d)
        if d && d.length == 8
          year, mon, day = d.slice(0, 4), d.slice(4, 2), d.slice(6, 2)
          date = ''
          if year.to_s.length > 0 && year != '0000'
            date += year
          end
          if mon.to_s.length && mon != '00'
            mon_int = mon.to_i
            date += '-' + sprintf("%02d", mon_int)

            if day.to_s.length && day != '00'
              day_int = day.to_i
              date += '-' + sprintf("%02d", day_int)
            end
          end
          return date
        end
        d
      end

      # takes a date string as YYYY, YYYY-MM or YYYY-MM-DD and returns
      # it as YYYYMMDD, using 0s for MM and DD if appropriate.
      def normalize_fuzzy_date(date_str)
        if date_str.present?
          date_str = date_str.gsub("-", "")
          if date_str.length < 8
            pad = 8 - date_str.length
            date_str += "0" * pad
          end
        end
        date_str
      end

      # Takes a date string 'd' and returns it in the YYYY-MM-DD format
      def date_dashes(d)
        d && d.length == 8 ? d.slice(0, 4) + "-" + d.slice(4, 2) + "-" + d.slice(6, 2) : d
      end

      # Takes a date_str like 'early 19th century' and returns a
      # normalized year range for it, like ['1800', '1826']. returns nil if date
      # str can't be normalized. Note that ranges are end-exclusive.
      #
      # Following Hanno Wijsman's feedback at the advisory board
      # meeting, centuries should include the "zero" year of the
      # "next" century. example: 15th century should include 1500
      # (therefore, its end date in an end-exclusive range would be
      # 1501). This is consistent with how incunables are popularly
      # understood as being written before 1501.
      #
      # TODO: handle negative dates
      def parse_approximate_date_str_into_year_range(date_str)

        date_str = date_str.strip

        # handle case of 'to'
        if / to /.match(date_str)
          pieces = date_str.split(/\s+to\s+/)
          if pieces.length == 2
            start_date_range = parse_approximate_date_str_into_year_range(pieces[0])
            end_date_range = parse_approximate_date_str_into_year_range(pieces[1])
            return [start_date_range[0], end_date_range[1] || end_date_range[0]]
          end
        end

        # handle case of something like 1860s.
        # this always assumes decade granularity: ie. 900s means the 1st decade of 10th century
        if /^\d+s$/.match(date_str)
          start_date = date_str.sub('s', '')
          end_date = nil
          if start_date[-1] == '0'
            end_date = (((start_date.to_i / 10) + 1) * 10).to_s
          end
          return [start_date, end_date]
        end

        # handle before and after by stripping out that qualifier and
        # running through this fn again. we bound start and end dates
        # with +/- 100 years to prevent odd search results
        # (ie. searching for 1500-1600 probably shouldn't pick up "after 1000")
        if /before/.match(date_str)
          range = parse_approximate_date_str_into_year_range(date_str.sub('before', '').strip)
          return [(range[1].to_i - 100).to_s, range[1]]
        end
        if /after/.match(date_str)
          range = parse_approximate_date_str_into_year_range(date_str.sub('after', '').strip)
          return [range[0], (range[0].to_i + 100).to_s]
        end

        # handle circa and exact years
        circa = false
        date_str_without_circa = date_str.dup
        ["circa", "ca.", "about"].each do |circa_str|
          match = /#{circa_str}/.match(date_str)
          if !circa && match.present?
            circa = true
            date_str_without_circa = date_str.sub(circa_str, "").strip
          end
        end

        # handle case of a year in the str / entire str is a year
        if (exact_date_match = /^(\d{4})$/.match(date_str_without_circa)).present? ||
           (exact_date_match = /^(\d{3})$/.match(date_str_without_circa)).present? ||
           (exact_date_match = /^(\d{2})$/.match(date_str_without_circa)).present?
          year = exact_date_match[1]
          buffer = circa ? 10 : 0;
          return [(year.to_i - buffer).to_s, (year.to_i + 1 + buffer).to_s]
        end

        # rest of this block handles centuries

        start_date, end_date = nil, nil

        # match strs like "3rd century"
        century = nil
        if (match = /(\d{1,2})(st|nd|rd|th|) c/.match(date_str)).present?
          century = (match[1].to_i - 1).to_s
        end

        # # match strs like "third century"
        (1..20).each do |n|
          if (match = /#{NumberTo.to_word_ordinal(n)} c/.match(date_str)).present?
            century = (n - 1).to_s
          end
        end

        if century.present?
          # match qualifiers
          case
          when /early/.match(date_str)
            start_date = century + "00"
            end_date = century + "26"
          when /mid/.match(date_str)
            start_date = century + "26"
            end_date = century + "76"
          when /late/.match(date_str)
            start_date = century + "76"
            end_date = (century.to_i + 1).to_s + "01"
          when /first quarter/.match(date_str)
            start_date = century + "00"
            end_date = century + "26"
          when /second quarter/.match(date_str)
            start_date = century + "26"
            end_date = century + "51"
          when /third quarter/.match(date_str)
            start_date = century + "51"
            end_date = century + "76"
          when /fourth quarter/.match(date_str)
            start_date = century + "76"
            end_date = (century.to_i + 1).to_s + "01"
          when /first third/.match(date_str)
            start_date = century + "00"
            end_date = century + "34"
          when /second third/.match(date_str)
            start_date = century + "34"
            end_date = century + "67"
          when /last third/.match(date_str)
            start_date = century + "67"
            end_date = (century.to_i + 1).to_s + "01"
          when /first half/.match(date_str)
            start_date = century + "00"
            end_date = century + "51"
          when /second half/.match(date_str)
            start_date = century + "51"
            end_date = (century.to_i + 1).to_s + "01"
          else
            if century.present?
              start_date = century + "00"
              end_date = (century.to_i + 1).to_s + "01"
            end
          end
        end

        start_date.present? ? [ start_date, end_date ] : nil
      end

      # parse a month and year string (ie. "June 1830") into 2-item
      # Array of start and end dates in the form YYYY-MM-DD (i.e
      # ["1830-06-01", "1830-06-31"]). If date string isn't parseable,
      # returns nil.
      def parse_month_and_year_into_date_range(date_str)
        month, year = nil, nil
        (1..12).each do |i|
          m = Date::MONTHNAMES[i]
          if (match = /#{m}/i.match(date_str)).present?
            month = i
            date_str = date_str.sub(match[0], "").strip
          end
        end
        if month.blank?
          (1..12).each do |i|
            m = Date::ABBR_MONTHNAMES[i]
            if (match = /#{m}/i.match(date_str)).present?
              month = i
              date_str = date_str.sub(match[0], "").strip
            end
          end
        end
        if (match = /^(\d+)$/.match(date_str)).present?
          year = match[1].to_i
        end

        if month.present? && year.present?
          start_date = DateTime.new(year, month, 1)
          end_date = Date.civil(year, month, -1) + 1.day
          return [start_date.strftime("%Y-%m-%d"), end_date.strftime("%Y-%m-%d")]
        end
        return nil
      end

      # helper method for solr indexing
      def range_bucket(value, size=10)
        if value.present?
          x = (value / size * size) + 1
          y = x + (size - 1)
          return "#{x} - #{y}"
        end
      end

      # returns a string of CSV data representing the the passed-in
      # 'objects' argument. The code block is a formatter that should
      # return an array of values for the passed-in object.
      def objects_to_csv(headers=nil, objects, &block)
        csv_data = ::CSV.generate_line headers
        objects.each do |object|
          csv_data << ::CSV.generate_line(yield(object))
        end
        csv_data
      end

      def int? s
        begin
          Integer(s)
        rescue Exception => e
          return false
        end
        return true
      end

      # wait for Solr to be 'current' (ie caught up with indexing). this
      # really can take 5 secs, if not more.
      def wait_for_solr_to_be_current
        host = ENV['SOLR_URL'].present? ? URI(ENV['SOLR_URL']).host : 'localhost'
        uri = "http://#{host}:8983/solr/admin/cores?action=STATUS&core=test"
        
        current = false
        count = 0
        while (!current && count < 5)
          sleep(1)
          result = Net::HTTP.get(URI(uri))
          current_str = /<bool name="current">(.+?)<\/bool>/.match(result)[1]
          current = current_str == 'true'
          count += 1
        end
      end

    end

  end

end

