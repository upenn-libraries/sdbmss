
# Engine for discovering similar Entries, which may be the same Manuscript

require 'set'

module SDBMSS

  puts "SDBMSS_SIMILAR_ENTRIES -> Deprecated, in part due to mysql injection vunlerabilities"

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

    # use a scale of 0 to this value, for determining best to worst
    # similarity.
    @@scale_to = 10

    def initialize strings
      @strings = strings.select(&:present?).map(&:upcase)
    end

    def -(x)
      # if one set is empty, give it a score of 5
      if x.strings.length == 0 || @strings.length == 0
        return 5
      end

      # we take the lowest (best) score, since a good match of ANY
      # memver of the set is a good indicator
      score = @@scale_to
      # cartesian product of arrays
      pairs = @strings.product(x.strings)
      scores = pairs.map { |pair| Levenshtein.normalized_distance(pair[0], pair[1]) * @@scale_to }
      score = scores.sort.first < @@scale_to ? scores.sort.first : @@scale_to
      Rails.logger.info("dist score: #{score}, '#{x.strings.inspect}' '#{@strings.inspect}'")
      score
    end
  end

  # Represents a point in a space of n dimensions used to calculate
  # the similarity between Entries.
  class Point < Hash

    def initialize(entry)
      # extract info from entry relevant for similarity matching

      store(:num_lines, entry.num_lines)
      store(:folios, entry.folios)
      store(:height, entry.height)
      store(:width, entry.width)
      store(:languages, LevenshteinStringSet.new(entry.entry_languages.map { |entry_language| entry_language.language.to_s }))
      store(:titles, LevenshteinStringSet.new(entry.entry_titles.map(&:title)))
    end

    # Calculates euclidean distance of 2 points. A distance of 0 means
    # exact match; as value increases, similarity decreases.
    def -(x)
      sum_of_squares = 0
      each do |k, v|
        v2 = x.fetch(k)
        # only calculate score if both values are present; this
        # prevents missing info on one of the entries from generating
        # a large difference and throwing off the calculation
        if v.present? && v2.present?
          score = (v - v2).abs
        else
          # one or both values are missing in the two Entries, so
          # give it a score of 7
          score = 7
        end
        # puts "score for key=#{k} = #{score}"
        sum_of_squares += score ** 2
      end
      Math.sqrt(sum_of_squares)
    end
  end

  # After instantiation, objects of this class are meant to be used as
  # an enumerable. e.g.:
  #
  # SimilarEntries.new(entry_id).each do |similar_entry|
  #   do something
  # end
  #
  # Each record is a hash containing two keys: 'distance', which is a
  # numeric measure of how 'far' (how dissimilar) an entry is, and
  # 'entry', which is keyed to the entry Object.
  class SimilarEntries

    include Enumerable

    # entry = entry for which we are looking for similar records
    def initialize entry
      @entry = entry
      # list of IDs of already matched manuscripts
      @already_matched = []#@entry.manuscript.entries.map(&:id)
      @p1 = Point.new(@entry)
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

      #### Possible candidates by similar dimension

      candidates_by_dimension = find_by_similar_dimenions
      count_by_dimension = candidates_by_dimension.count

      #### Possible candidates where candidate is catalog entry for a sale in this entry's provenance

      provenance_dates = @entry.provenance.map(&:start_date).select { |d| d.present? }

      candidates_by_provenance_date = find_by_provenance_dates(provenance_dates)
      count_by_provenance_date = candidates_by_provenance_date.count

      if candidates_by_provenance_date.count > 0
        provenance_dates_sql = provenance_dates.map { |d| "'#{d}'" }.join(",")
        candidates_by_provenance_date = Entry.joins(:source).where("sources.date in (#{provenance_dates_sql})")
        count_by_provenance_date = candidates_by_provenance_date.count
      end

      Rails.logger.info "SimilarEntries: # of candidates found: (#{count_by_dimension} by dimension; #{count_by_provenance_date} by prov date) for entry #{@entry.id}"

      if count_by_dimension < 250 && count_by_provenance_date < 500
        entries = candidates_by_dimension + candidates_by_provenance_date
        entries.each do |entry|
          if (entry.id != @entry.id) && (! @already_matched.member?(entry.id))
            p2 = Point.new(entry)
            distance = @p1 - p2
            Rails.logger.debug "distance=#{distance}"
            @similar_entries << { distance: distance, entry: entry }
          end
        end

        @similar_entries.select! { |e| e[:distance] <= 20 }

        @similar_entries.sort! { |x,y| x[:distance] <=> y[:distance] }
      end
    end

    def find_by_similar_dimenions
      buffer_folios = 5
      buffer_width = 5
      buffer_height = 5

      candidates_by_dimension = Entry.all.with_associations.order('id')
      if @entry.folios.present?
        candidates_by_dimension = candidates_by_dimension.where("folios > #{@entry.folios - buffer_folios}")
        candidates_by_dimension = candidates_by_dimension.where("folios < #{@entry.folios + buffer_folios}")
      end
      if @entry.width.present?
        candidates_by_dimension = candidates_by_dimension.where("width > #{@entry.width - buffer_width}")
        candidates_by_dimension = candidates_by_dimension.where("width < #{@entry.width + buffer_width}")
      end
      if @entry.height.present?
        candidates_by_dimension = candidates_by_dimension.where("height > #{@entry.height - buffer_height}")
        candidates_by_dimension = candidates_by_dimension.where("height < #{@entry.height + buffer_height}")
      end
      candidates_by_dimension
    end

    def find_by_provenance_dates(provenance_dates)
      candidates_by_provenance_date = []

      if provenance_dates.count > 0
        provenance_dates_sql = provenance_dates.map { |d| "'#{d}'" }.join(",")
        candidates_by_provenance_date = Entry.all.with_associations.joins(:source).where("sources.date in (#{provenance_dates_sql})")
      end
      candidates_by_provenance_date
    end

  end

end
