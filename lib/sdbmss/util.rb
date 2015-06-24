
require 'csv'
require 'date'
require 'net/http'

require 'active_support/all'

module SDBMSS

  module Util

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

      # Takes a date string 'd' and returns it in the YYYY-MM-DD format
      def date_dashes(d)
        d && d.length == 8 ? d.slice(0, 4) + "-" + d.slice(4, 2) + "-" + d.slice(6, 2) : d
      end

      # does a preliminary check and returns true if str is parseable
      # by #normalize_approximate_date_str_to_year_range
      def resembles_approximate_date_str(date_str)
        /(about|circa|ca|before|after|early|mid|late|cent|c\.|to)/.match(date_str).present? ||
          /\ds/.match(date_str).present?
      end

      # Takes a date_str like 'early 19th century' and returns a
      # normalized year range for it, like ['1800', '1825']. returns nil if date
      # str can't be normalized.
      #
      # TODO: handle negative dates
      def normalize_approximate_date_str_to_year_range(date_str)

        date_str = date_str.strip

        # handle case of 'to'
        if / to /.match(date_str)
          pieces = date_str.split(/\s+to\s+/)
          if pieces.length == 2
            start_date_range = normalize_approximate_date_str_to_year_range(pieces[0])
            end_date_range = normalize_approximate_date_str_to_year_range(pieces[1])
            return [start_date_range[0], end_date_range[1] || end_date_range[0]]
          end
        end

        # handle case of something like 1860s.
        # this always assumes decade granularity: ie. 900s means the 1st decade of 10th century
        if /\ds/.match(date_str)
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
          range = normalize_approximate_date_str_to_year_range(date_str.sub('before', '').strip)
          return [(range[1].to_i - 100).to_s, range[1]]
        end
        if /after/.match(date_str)
          range = normalize_approximate_date_str_to_year_range(date_str.sub('after', '').strip)
          return [range[0], (range[0].to_i + 100).to_s]
        end

        circa = !! (/circa/.match(date_str) || /ca\./.match(date_str) || /about/.match(date_str))

        # match any 4-digit number in the str or test if entire str is
        # a number
        if (exact_date_match = /(\d{4})/.match(date_str)).present? ||
           (exact_date_match = /^(\d{4})$/.match(date_str)).present? ||
           (exact_date_match = /^(\d{3})$/.match(date_str)).present? ||
           (exact_date_match = /^(\d{2})$/.match(date_str)).present?
          year = exact_date_match[1]
          buffer = circa ? 10 : 0;
          return [(year.to_i - buffer).to_s, (year.to_i + 1 + buffer).to_s]
        end

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
            end_date = (century.to_i + 1).to_s + "00"
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
            end_date = (century.to_i + 1).to_s + "00"
          when /first third/.match(date_str)
            start_date = century + "00"
            end_date = century + "34"
          when /second third/.match(date_str)
            start_date = century + "34"
            end_date = century + "67"
          when /last third/.match(date_str)
            start_date = century + "67"
            end_date = (century.to_i + 1).to_s + "00"
          when /first half/.match(date_str)
            start_date = century + "00"
            end_date = century + "51"
          when /second half/.match(date_str)
            start_date = century + "51"
            end_date = (century.to_i + 1).to_s + "00"
          else
            if century.present?
              start_date = century + "00"
              end_date = (century.to_i + 1).to_s + "00"
            end
          end
        end

        [ start_date, end_date ]
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
        csv_data = CSV.generate_line headers
        objects.each do |object|
          csv_data << CSV.generate_line(yield(object))
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
        current = false
        count = 0
        while (!current && count < 5)
          sleep(1)
          result = Net::HTTP.get(URI('http://localhost:8983/solr/admin/cores?action=STATUS&core=test'))
          current_str = /<bool name="current">(.+?)<\/bool>/.match(result)[1]
          current = current_str == 'true'
          count += 1
        end
      end

    end

  end

end

