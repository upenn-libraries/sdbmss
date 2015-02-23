
# Engine for discovering similar Entries, which may be the same Manuscript

require 'set'

module SDBMSS

  class StringSet

    attr_accessor :strings

    def initialize strings
      @strings = Set.new(strings.map(&:upcase).map { |s| s.gsub(/\s/, "") })
    end

    def -(x)
      puts "diffing #{x.strings.inspect} with #{@strings.inspect}"
      union = x.strings | @strings
      retval = 10
      pct = (@strings.count - union.count) / @strings.count
      retval = pct * 10 if pct > 0
      puts "score: #{retval}"
      return retval
    end

  end

  # Encapsulates a set of strings for comparison to another set,
  # according to Levenshtein algorithm for string similarity.
  class LevenshteinStringSet

    attr_accessor :strings

    def initialize strings
      @strings = strings.map(&:upcase)
    end

    def -(x)
      # if one set is empty, give it a score of 5
      if x.strings.length == 0 || @strings.length == 0
        return 5
      end

      # we take the lowest (best) score, since a good match of any one
      # memebr of the set is a good indicator
      score = 10
      @strings.each do |s1|
        x.strings.each do |s2|
          d = Levenshtein.normalized_distance(s1, s2) * 10
          score = d if d < score
        end
      end
      Rails.logger.info("dist score: #{score}, '#{x.strings.inspect}' '#{@strings.inspect}'")
      score
    end
  end

  class SimilarEntries

    include Enumerable

    # entry = entry for which we are looking for similar records
    def initialize entry
      @entry = entry
      # list of IDs of already matched manuscripts
      @already_matched = @entry.get_entries_for_manuscript.map(&:id)
      @p1 = create_point(@entry)
      @similar_entries = nil
    end

    # iterates over similar entries
    def each(&block)
      find_similar_entries if @similar_entries.nil?
      @similar_entries.each do |candidate|
        block.call(candidate)
      end
    end

    private

    def find_similar_entries

      @similar_entries = []

      buffer_folios = 10
      buffer_width = 10
      buffer_height = 10

      # Narrow down pool of possible candidates to something reasonable
      entries = Entry.all.order('id')
      if @entry.folios.present?
        entries = entries.where("folios > #{@entry.folios - buffer_folios}")
        entries = entries.where("folios < #{@entry.folios + buffer_folios}")
      end
      if @entry.width.present?
        entries = entries.where("width > #{@entry.width - buffer_width}")
        entries = entries.where("width < #{@entry.width + buffer_width}")
      end
      if @entry.height.present?
        entries = entries.where("height > #{@entry.height - buffer_height}")
        entries = entries.where("height < #{@entry.height + buffer_height}")
      end

      count = entries.count()
      #puts "Calculating record's similarity to other #{count} records"

      if count < 500

        entries.each do |entry|
          if (entry.id != @entry.id) && (! @already_matched.member?(entry.id))
            p2 = create_point(entry)
            distance = distance(@p1, p2)
            @similar_entries << { distance: distance, entry: entry }
          end
        end

        @similar_entries.sort! { |x,y| x[:distance] <=> y[:distance] }
      else
        print "Too many similar candidates for entry #{@entry.id}, skipping"
      end
    end

    private

    def create_point entry
      return [ entry.num_lines || 0, entry.folios || 0, entry.height || 0, entry.width || 0, LevenshteinStringSet.new(entry.entry_titles.map(&:title)) ]
    end

    # Calculates euclidean distance of 2 points. A distance of 0 means
    # exact match; as value increases, similarity decreases.
    def distance p1, p2
      sum_of_squares = 0
      p1.each_index do |i|
        sum_of_squares += (p1[i] - p2[i]).abs ** 2
      end
      Math.sqrt(sum_of_squares)
    end

  end

end
