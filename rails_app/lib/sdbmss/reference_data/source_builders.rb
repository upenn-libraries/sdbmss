module SDBMSS::ReferenceData
  # Example of an online auction catalog
  class Ader < RefDataBase
    def initialize
      create_source
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.auction_catalog,
        date: "2015-03-19",
        title: "Livres ancienes et modernes",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_INTERNET,
        date_accessed: "2015-03-10",
        link: "http://www.ader-paris.fr/flash/index.jsp?id=21247&idCp=97&lng=fr",
        created_by: lransom
      )
    end
  end

  # Example of an email
  class Email < RefDataBase
    def initialize
      create_source
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.unpublished,
        title: "Email sent by Jeff Chiu",
        author: "Lynn Ransom",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_PERSONAL_COMMUNICATION,
        date_accessed: "2015-03-10",
        created_by: lransom
      )
    end
  end

  # Example of a personal observation
  class PersonalObservation < RefDataBase
    def initialize
      create_source
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.unpublished,
        title: "not required in personal observation OR March 9, 2015, visit",
        author: "Ransom, Lynn",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_PRIVATE_COLLECTION,
        date_accessed: "2015-03-09",
        location: "Philadelphia, PA",
        created_by: lransom
      )

      SourceAgent.create!(
        source: @source,
        agent: find_or_create_agent("Chiu, Jeff"),
        role: SourceAgent::ROLE_INSTITUTION
      )
    end
  end

  # Example of EBay
  class EBay < RefDataBase
    def initialize
      create_source
      reindex create_entry
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.online,
        title: "Ebay",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_INTERNET,
        date_accessed: "2015-03-16",
        link: "www.ebay.com",
        created_by: lransom
      )

      SourceAgent.create!(
        source: @source,
        agent: find_or_create_agent("Ebay"),
        role: SourceAgent::ROLE_SELLING_AGENT
      )
    end

    def create_entry
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "371277701327",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        height: 100,
        width: 68,
        miniatures_fullpage: 1,
        manuscript_binding: "Original wooden boards",
        manuscript_link: "http://www.ebay.com/itm/MEDIEVAL-Miniature-CRUCIFIXION-c1450-A-D-Book-of-Hours-Vellum-MISSAL-MANUSCRIPT-/371277701327?pt=LH_DefaultDomain_0&hash=item5671e020cf",
        other_info: "This is a fragment. Folio count not provided.",
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 3299.0,
        currency: "USD",
        sold: Sale::TYPE_SOLD_UNKNOWN
      )
      SaleAgent.create!(
        sale: sale,
        agent: find_or_create_agent("Ebay"),
        role: SaleAgent::ROLE_SELLING_AGENT
      )
      SaleAgent.create!(
        sale: sale,
        agent: find_or_create_agent("weisse-lilie-art"),
        role: SaleAgent::ROLE_SELLER_OR_HOLDER
      )

      EntryTitle.create!(
        entry: entry,
        title: "Book of Hours or Missal, fragment"
      )

      ed = EntryDate.new(entry: entry, observed_date: "about 1450 A.D.")
      ed.normalize_observed_date
      ed.save!

      EntryPlace.create!(
        entry: entry,
        place: find_or_create_unscoped(Place, name: "France")
      )

      Provenance.create!(
        entry: entry,
        comment: "Inscription on a leaf: Missale m S. P. Sharrock Ushaw. [Ushaw is possible reference to Ushaw College, Durham University?].",
        observed_name: "S. P. Sharrock Ushaw"
      )

      Comment.create!(
        comment: "A google search on \"sharrock ushaw\" returned a website from Ushaw College Library Special Collections Catalogue. The Ushaw College History Papers archive contains this reference: UC/H306 13 November 1815 Letter from J.B. Marsh to William Hogarth: financial affairs of P.J. Sharrock, and the offer of his books to Ushaw's library. (see http://reed.dur.ac.uk/xtf/view?docId=ead/ush/uchistor.xml).",
        created_at: DateTime.now,
        created_by_id: lransom.id
      )

      entry
    end
  end

  # Example of auction catalog that is online
  class VanDeWiele < RefDataBase
    def initialize
      create_source
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.auction_catalog,
        date: "2015",
        title: "Brafa 2015",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_INTERNET,
        date_accessed: "20150317",
        link: "http://www.marcvandewiele.com",
        created_by: lransom
      )

      SourceAgent.create!(
        source: @source,
        agent: find_or_create_agent("Marc Van de Wiele"),
        role: SourceAgent::ROLE_SELLING_AGENT
      )
    end
  end

  # Example of spreadsheet emailed to Lynn (unpublished source)
  class Duke < RefDataBase
    def initialize
      create_source
      reindex create_entry
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.unpublished,
        title: "Duke Greek MS codex MSS.xls",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_PERSONAL_COMMUNICATION,
        date_accessed: "20150317",
        location: "Philadelphia, PA",
        created_by: lransom
        # comments: "Spreadsheet created and shared by curators at David Rubenstein Library, Duke University.",
      )

      SourceAgent.create!(
        source: @source,
        agent: find_or_create_agent("Duke University, David Rubenstein Library"),
        role: SourceAgent::ROLE_INSTITUTION
      )
    end

    def create_entry
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "Greek MS 001",
        transaction_type: Entry::TYPE_TRANSACTION_NONE,
        institution: find_or_create_agent("Duke University, David Rubenstein Library"),
        folios: 198,
        num_lines: 41,
        num_columns: 1,
        height: 306,
        width: 227,
        manuscript_binding: "Clam-shell box",
        other_info: "Complete New Testament in Greek. Order of Books:  Gospels, Acts, James, Pauline Epistles, general epistles except for James, Apocalypse. Gregory-Aland 1780.",
        created_by: lransom,
        approved: true
      )

      EntryTitle.create!(
        entry: entry,
        title: "New Testament"
      )

      ed = EntryDate.new(entry: entry, observed_date: "1200")
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: find_or_create_unscoped(Language, name: "Greek")
      )

      EntryMaterial.create!(
        entry: entry,
        material: "Parchment"
      )

      entry
    end
  end

  # Example of a journal article
  class Steinhauser < RefDataBase
    def initialize
      create_source
      reindex create_entry
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.other_published,
        date: "2014",
        title: "\"A Catalogue of Medieval and Renaissance Manuscripts Located at Villanova University,\" Manuscripta, vol. 57:2",
        author: "Kenneth B. Steinhauser",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_LIBRARY,
        date_accessed: "20150323",
        location_institution: "University of Pennsylvania Libraries",
        location: "Philadelphia, PA",
        created_by: lransom
      )
    end

    def create_entry
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "OM 1",
        transaction_type: Entry::TYPE_TRANSACTION_NONE,
        institution: find_or_create_agent("Villanova University, Falvey Memorial Library"),
        folios: 212,
        num_lines: 26,
        num_columns: 1,
        height: 96,
        width: 56,
        initials_decorated: 1,
        manuscript_binding: "modern light brown inlaid morocco with red and gold floral and leaf decoration",
        created_by: lransom,
        approved: true
      )

      EntryTitle.create!(
        entry: entry,
        title: "Opera minora"
      )

      EntryAuthor.create!(
        entry: entry,
        observed_name: "(pseudo-) Augustine",
        author: find_or_create_author("Pseudo-Augustine, Saint, Bishop of Hippo")
      )

      ed = EntryDate.new(entry: entry, observed_date: "14th century")
      ed.normalize_observed_date
      ed.save!

      EntryMaterial.create!(
        entry: entry,
        material: "Parchment"
      )

      Provenance.create!(
        entry: entry,
        comment: "\"E.H.\" is an unknown 19th century or early 20th century owner.",
        observed_name: "E.H."
      )

      Provenance.create!(
        entry: entry,
        comment: "Provenance info given in De Ricci, II: 2132.",
        provenance_agent: find_or_create_agent("Leighton, W. J."),
        direct_transfer: true
      )

      Provenance.create!(
        entry: entry,
        start_date: "19181114",
        comment: "Provenance info given in De Ricci, II: 2132.",
        provenance_agent: find_or_create_agent("Sotheby's"),
        direct_transfer: true
      )

      Provenance.create!(
        entry: entry,
        comment: "Provenance info given in De Ricci, II: 2132.",
        provenance_agent: find_or_create_agent("James Tregaskis (Firm)"),
        observed_name: "James Tregaskis",
        direct_transfer: true
      )

      Provenance.create!(
        entry: entry,
        comment: "Provenance info given in De Ricci, II: 2132.",
        provenance_agent: find_or_create_agent("John F. Lewis"),
        direct_transfer: true
      )

      Provenance.create!(
        entry: entry,
        comment: "Provenance info given in De Ricci, II: 2132.",
        provenance_agent: find_or_create_agent("Villanova College")
      )

      entry
    end
  end
end
