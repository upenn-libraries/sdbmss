require 'csv'

namespace :suggestion do
  desc 'test suggestion success'
  task :test => :environment do
    def test(sample, manuscripts)
      total = 0
      manuscripts.each do |manuscript|
        if manuscript.entries.count > 1
          suggestions = Sunspot.more_like_this(manuscript.entries.first) do
            fields *sample
            #fields :title_search, :place_search, :author_search, :language_search, :manuscript_date_search, :folios_search
            # without :id, [collect entry_ids from manuscript]
            #minimum_term_frequency 3
            boost_by_relevance true
            order_by :score, :desc
            paginate :per_page => 10, :page => 1
          end
          matched = 0
          unmatched = 0
          manuscript.entries[1..manuscript.entries.count].each do |entry|
            if suggestions.results.include? entry
              matched += 1
            else
              unmatched += 1
            end
          end
          ratio = matched / (matched + unmatched * 1.0)
          #puts "#{manuscript.public_id} :  #{ratio}"
          total += ratio
        end
      end
      return total / (manuscripts.count * 1.0)
      #puts "Final Ratio: #{}"
    end
    
    results = []

    manuscripts = Manuscript.order("RAND()").first(1000)
    possible = [:language_search, :artist_search, :scribe_search, :use_search, :binding_search]

=begin
    possible.combination(5).each do |comb|
      comb = [:title_search, :place_search] + comb
      puts "Testing #{comb.map(&:to_s).join(' ')}"
      results.push([comb.map(&:to_s).join(' '), test(comb, manuscripts)])
    end
    possible.combination(4).each do |comb|
      comb = [:title_search, :place_search] + comb
      puts "Testing #{comb.map(&:to_s).join(' ')}"
      results.push([comb.map(&:to_s).join(' '), test(comb, manuscripts)])
    end

    possible.combination(3).each do |comb|
      comb = [:title_search, :place_search] + comb
      puts "Testing #{comb.map(&:to_s).join(' ')}"
      results.push([comb.map(&:to_s).join(' '), test(comb, manuscripts)])
    end

    possible.combination(2).each do |comb|
      comb = [:title_search, :place_search] + comb
      puts "Testing #{comb.map(&:to_s).join(' ')}"
      results.push([comb.map(&:to_s).join(' '), test(comb, manuscripts)])
    end

    possible.combination(1).each do |comb|
      comb = [:title_search, :place_search] + comb
      puts "Testing #{comb.map(&:to_s).join(' ')}"
      results.push([comb.map(&:to_s).join(' '), test(comb, manuscripts)])
    end
=end    

    puts "Testing without folios"
    results.push(["without folios", test([:title_search, :place_search] + possible, manuscripts)])
    puts "Testing folios"
    results.push(["with folios", test([:title_search, :place_search, :folios_search] + possible, manuscripts)])

    CSV.open('suggestions_test2.csv', 'wb') do |csv|
      csv << ["Fields", "Ratio (Matched / Total)"]
      results.each do |result|
        csv << result
      end
    end
    #puts "Testing all: #{possible.map(&:to_s).join(' ')}"
    #test(possible)

  end
end

# folios_search needs to be reindexed...