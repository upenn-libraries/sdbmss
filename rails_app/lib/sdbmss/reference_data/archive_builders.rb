module SDBMSS::ReferenceData
  class Manuscripts < RefDataBase
    def initialize
      @m = Manuscript.create!(created_by: lransom)
      [Entry.first, Entry.last].compact.uniq.each do |entry|
        EntryManuscript.create!(manuscript: @m, entry: entry, relation_type: "is")
      end
    end
  end

  class DericciArchive < RefDataBase
    def initialize
      create_records
      create_notes
      create_sales
    end

    def create_records
      5.times do |i|
        DericciRecord.create!(
          name: "Zetland (Earl of) the #{i}st",
          dates: "(1795–187#{3 + i})",
          place: "London, England.",
          url: "https://dericci.senatehouselibrary.ac.uk/web_pdf/dericci_zetland_earl_#{i}.pdf",
          cards: (i + 1),
          size: "<1 MB",
          other_info: nil,
          senate_house: "[Senate House MS90#{i}/3/11]"
        )
      end
    end

    def create_notes
      5.times do |i|
        DericciNote.create!(
          name: "Topography, Wales, Montmouthshire (0.00#{i})",
          cards: "#{i * 3} cards",
          size: "#{i} MB",
          senate_house: "Senate House MS901/4/#{i + 1}",
          link: "https://dericci.senatehouselibrary.ac.uk/web_pdf/dericci_misc_topography_montmouthshire.pdf"
        )
      end
    end

    def create_sales
      5.times do |i|
        DericciSale.create!(
          name: "Dated Sales, 1907 to 1938",
          cards: "#{i + 1}0 cards",
          size: "#{i + 1} MB",
          senate_house: "Senate House MS90#{i - 1}/3/11",
          link: "https://dericci.senatehouselibrary.ac.uk/web_pdf/dericci_dated_sales_1907_1938.pdf"
        )
      end
    end
  end
end
