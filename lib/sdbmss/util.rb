
require 'date'

module SDBMSS

  module Util

    class << self

      # Does a SQL select query in batches, passing each row to the
      # code block
      def batch(conn, sql, ctx: nil, limit: 1000, batch_wrapper: nil, &block)
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
            puts "Processed #{ctx[:count]} records so far in batch(): overall rate: #{rate} records/sec"

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

      # returns a reasonably formatted YYYY-MM-DD str based on a
      # YYYYMMDD str value, which may have 0's in it
      def format_fuzzy_date(d)
        if d
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
      
    end

  end
  
end

