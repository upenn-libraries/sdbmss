
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

      # returns a reasonably formatted YYYY-Mon-DD str based on a
      # YYYYMMDD str value, which may have 0's in it
      def format_fuzzy_date(d)
        if d && d.length == 8
          year, mon, day = d.slice(0, 4), d.slice(4, 2), d.slice(6, 2)
          date = ''
          if year.to_s.length > 0 && year != '0000'
            date += year
          end
          if mon.to_s.length && mon != '00'
            # gracefully handle bad months, which do exist in the data
            mon_int = mon.to_i
            if mon_int >= 1 && mon_int <= 12
              date += '-' + Date::ABBR_MONTHNAMES[mon_int]
            else
              date += '-' + mon
            end
          end
          if day.to_s.length && day != '00'
            date += '-' + day
          end
          return date
        end
        d
      end

      # Takes a date string 'd' and returns it in the YYYY-MM-DD format
      def date_dashes(d)
        d && d.length == 8 ? d.slice(0, 4) + "-" + d.slice(4, 2) + "-" + d.slice(6, 2) : d
      end

      # Takes a date_str like 'early 19th century' and returns a
      # normalized date value for it, like '1825'. returns nil if date
      # str can't be normalized.
      def normalize_approximate_date_str(date_str)
        if (exact_date_match = /(\d{4})/.match(date_str)).present?
          return exact_date_match[1]
        else
          century, decade = "", "00"
          qualifier_match = /(early|mid|late)/.match(date_str)
          century_match = /(\d{1,2})/.match(date_str)
          if century_match
            century = (century_match[1].to_i - 1).to_s
          end
          case
          when /early/.match(date_str)
            decade = "25"
          when /mid/.match(date_str)
            decade = "50"
          when /late/.match(date_str)
            decade = "75"
          end
          century.present? ? century + decade : nil
        end
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

