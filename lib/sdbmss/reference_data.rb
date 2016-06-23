# coding: utf-8

# This is a library that creates "reference data", containing entries
# from actual catalogs. See the /reference_data directory in the
# project root for digital copies of the original sources.
#
# The purpose of this is to verify we can properly store all types of
# entries, and to keep a normative record of the fields where various
# bits of data should live, since this is not always obvious or easy
# to remember for the many types of sources and entries.
#
# Think of this as an "integration test" of all our models as a
# organic whole.
#
# This gets used by the test suite, and also in development to
# re-create data in case we want to examine something.

module SDBMSS::ReferenceData

  class << self
    def create_all
      JonathanHill.new
      PennCatalog.new
      Pirages.new
      DeRicci.new
      Ader.new
      Email.new
      PersonalObservation.new
      EBay.new
      VanDeWiele.new
      Duke.new
      Steinhauser.new
    end
  end

  class RefDataBase
    def reindex (entry)
      entry.reload
      Sunspot.index entry
    end

    def lransom
      user = User.find_by(username: "lransom")
      if user.blank?
        user = User.create!(
          username: "lransom",
          email: "lransom@upenn.edu",
          password: "12345678",
          password_confirmation: "12345678"
        )
      end
      user
    end
  end

  class JonathanHill < RefDataBase

    def initialize
      create_source
      reindex create_entry_one
      reindex create_entry_three
      reindex create_entry_four
      reindex create_entry_five
      reindex create_entry_nine
      reindex create_entry_fourteen
    end

    def create_source
      @hill = Name.find_or_create_agent("Jonathan A. Hill")
      @source = Source.create!(
        source_type: SourceType.auction_catalog,
        date: "20150101",
        title: "Catalogue 213: Fine and Important Manuscripts and Printed Books",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        link: "https://www.jonathanahill.com/lists/HomePageFiles/Cat%20213%20unillustrated%20proofs.pdf",
        medium: Source::TYPE_MEDIUM_INTERNET,
        created_by: lransom,
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: @hill,
        role: SourceAgent::ROLE_SELLING_AGENT
      )
    end

    def create_entry_one
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "1",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        folios: 166,
        num_columns: 2,
        height: 255,
        width: 185,
        initials_decorated: 15,
        manuscript_binding: 'Ca. 1900, with the gilt stamp of "L. Broca" (Lucien Broca), red morocco over pasteboard, upper and lower cover with gilt double fillet borders enclosing a gilt central medallion; five raised bands on spine, compartments repeating gilt motif, edges and turn-ins gilt.',
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 270000,
        currency: 'USD',
        sold: Sale::TYPE_SOLD_NO,
      )
      sale_agent = SaleAgent.create!(
        sale: sale,
        agent: @hill,
        role: SaleAgent::ROLE_SELLING_AGENT
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Confessiones',
        common_title: 'Confessions',
      )
      EntryTitle.create!(
        entry: entry,
        title: 'Sermones ad fratrem suos hermitas',
      )
      EntryTitle.create!(
        entry: entry,
        title: 'Epistola beati Valerij ad Augustinum',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Augustine, Saint, Bishop of Hippo')
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Pseudo-Augustine, Saint, Bishop of Hippo'),
        observed_name: 'Pseudo-Augustine'
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Valerius, Bishop of Hippo')
      )

      ed = EntryDate.new(entry: entry, observed_date: "ca. 1425-1450")
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Latin')
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'Italy, Tuscany, Florence'),
        uncertain_in_source: true,
      )

      Provenance.create!(
        entry: entry,
        comment: "Bookplate.",
        provenance_agent: Name.find_or_create_agent("Tomkinson, Michael"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: '19220700',
        comment: "Bookplate. His sale, July 1922 (day of sale not given), lot. 1027.",
        provenance_agent: Name.find_or_create_agent("Sotheby's"),
      )

      Provenance.create!(
        entry: entry,
        comment: "Bookplate.",
        observed_name: "Bibliotheca Philosophica Hermetica, J. R. Ritman, Amsterdam",
        provenance_agent: Name.find_or_create_agent("Ritman, J. R."),
      )

      Provenance.create!(
        entry: entry,
        observed_name: "European private collection",
      )

      entry
    end

    def create_entry_three
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "3",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        folios: 72,
        num_lines: 34,
        num_columns: 2,
        height: 530,
        width: 230,
        miniatures_small: 32,
        manuscript_binding: 'End of 15th-early 16th century, panelled leather, blind stamped (including a roll stamp, with fleur-de-lys, crowned fleur-de-lys, and a crowned dolphin), with metal corners & centerpieces',
        other_info: 'Written in black ink in Littera batarda',
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 1650000,
        sold: Sale::TYPE_SOLD_UNKNOWN,
      )
      sale_agent = SaleAgent.create!(
        sale: sale,
        agent: @hill,
        role: SaleAgent::ROLE_SELLING_AGENT
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Histoire de la Premiere Guerre Punique',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Bruni, Leonardo')
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Lebegue, Jean'),
        role: 'Tr',
      )

      ed = EntryDate.new(entry: entry, observed_date: "ca. 1450")
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'French')
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'France, Paris')
      )

      Provenance.create!(
        entry: entry,
        end_date: '18030000',
        comment: "He died in 1803.",
        observed_name: "Comte Charles d'Oultremont (1753-1803)",
        provenance_agent: Name.find_or_create_agent("d'Oultremont, Charles, Comte"),
      )

      Provenance.create!(
        entry: entry,
        start_date: "18030000",
        end_date: "18300426",
        provenance_agent: Name.find_or_create_agent("d'Oultremont, Anne-Henriette, Comtesse"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: "18300426",
        provenance_agent: Name.find_or_create_agent("P. H. Carpentiers"),
        comment: "Catalogue title: Catalogus van eene fraye verzameling historische, letterkundige, ...boeken, nagalaten door wylen mevrowe de gravin douairiere d'Oultremont...op maendag 26 April 1830.",
      )

      Provenance.create!(
        entry: entry,
        comment: 'Loose letter to "Dear Yates," datable to 1884 or later with related British Museum request slips (Thompson and Bright: A Family of "Bibliophiles, see also New York, PML. M 266.',
        provenance_agent: Name.find_or_create_agent("Thompson-Yates, Samuel Ashton"),
      )

      entry
    end

    def create_entry_four
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "4",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 2400000,
        sold: Sale::TYPE_SOLD_UNKNOWN,
      )
      sale_agent = SaleAgent.create!(
        sale: sale,
        agent: @hill,
        role: SaleAgent::ROLE_SELLING_AGENT
      )

      EntryTitle.create!(
        entry: entry,
        title: 'De officiis',
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Paradoxa stoicorum',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Cicero, Marcus Tullius')
      )

      # WARNING: we didn't fill in all MS details; we concentrated on
      # provenance instead

      Provenance.create!(
        entry: entry,
        comment: "Arms of Engelhard of Swabia in lower margin fol. 1r: gules, three shamrocks argent (Rietstap, Armorial general, I. P. 614, pl. CCLXIX",
        provenance_agent: Name.find_or_create_agent("Engelhard of Swabia"),
      )

      Provenance.create!(
        entry: entry,
        end_date: "19071113",
        comment: "Armorial ink-stamped collector's mark: three coquilles, two and one, surounded by the Garter of the Golden Fleece and surmounted by a prince's coronet (fol. Ir, Riestap, pl. CXCVIIII). Catalogue without manuscripts.",
        observed_name: "Clemens Lothar von Wenzel, Furst von Metternich (1773-1859)",
        provenance_agent: Name.find_or_create_agent("Metternich, Clemens Wenzel Lothar, Fürst von"),
      )

      Provenance.create!(
        entry: entry,
        comment: 'Bell lived in Gwynned Valley, Pennsylvania.',
        observed_name: "Dr. Edward Henry Bell",
        provenance_agent: Name.find_or_create_agent("Bell, Edward Henry"),
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Hartz, Raymond and Elizabeth"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: "19911212",
        comment: 'lot 162',
        provenance_agent: Name.find_or_create_agent("Sotheby's"),
      )

      Provenance.create!(
        entry: entry,
        observed_name: "European Private Collection",
      )

      entry
    end

    def create_entry_five
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "5",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 180000,
        currency: "USD",
        sold: Sale::TYPE_SOLD_UNKNOWN,
      )
      sale_agent = SaleAgent.create!(
        sale: sale,
        agent: @hill,
        role: SaleAgent::ROLE_SELLING_AGENT
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Epistolae ad Familiares',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Cicero, Marcus Tullius')
      )

      ed = EntryDate.new(entry: entry, observed_date: "ca. 1460-1470")
      ed.normalize_observed_date
      ed.save!

      EntryArtist.create!(
        entry: entry,
        artist: Name.find_or_create_artist('Francesco di Antonio del Chierico')
      )

      EntryScribe.create!(
        entry: entry,
        scribe: Name.find_or_create_scribe('Ser Pietro Di Bernardo Cennini')
      )

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Latin'),
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'Italy, Florence')
      )

      # WARNING: we didn't fill in all MS details; we concentrated on
      # provenance instead

      Provenance.create!(
        entry: entry,
        observed_name: "Unidentified original owner",
        comment: "unidentified coat of arms on fol. 2r, now erased.",
      )

      Provenance.create!(
        entry: entry,
        comment: 'Perhaps a Sicilian owner by the late 16th-17th century when manuscript received present binding; presumably contemorary to the inscriptions on the flyleaf: "Di don Francesco st.st.lia. Di Don Domenico."',
        observed_name: "Sicilian collector",
      )

      Provenance.create!(
        entry: entry,
        comment: 'Book label with initials (gilt on blue).',
        observed_name: "R. I. A."
      )

      Provenance.create!(
        entry: entry,
        comment: 'bookplate; F. 159 in her library.',
        provenance_agent: Name.find_or_create_agent("Feltrinelli, Giannalisa"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: "19971203",
        provenance_agent: Name.find_or_create_agent("Christie's London"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Bernard Quaritch Ltd."),
        observed_name: "Bernard Quaritch",
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Friedlaender, Helmut N."),
        comment: "Bookplate.",
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        end_date: "20010423",
        provenance_agent: Name.find_or_create_agent("Christie's NY"),
      )

      entry
    end

    def create_entry_nine
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "9",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        folios: 61,
        num_lines: 32,
        num_columns: 1,
        height: 237,
        width: 172,
        manuscript_binding: 'Italian paneled brow leather over wooden boards, tooled in blind with ropework border.',
        other_info: 'Manuscript is dated in an inscription 30 December. 1480. Includes one full-length illuminated border.',
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 120000,
        currency: 'USD',
        sold: Sale::TYPE_SOLD_UNKNOWN,
        sale_agents_attributes: [
          {
            agent: @hill,
            role: SaleAgent::ROLE_SELLING_AGENT
          }
        ]
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Saturae I-XVI',
        common_title: 'Satires I-XVI',
      )
      EntryTitle.create!(
        entry: entry,
        title: 'Introductory hexameter to Satires II, IV-VIII',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Juvenal'),
        observed_name: 'Iuvenalis, Decimus Iunius',
      )
      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Guarino Veronese'),
        observed_name: 'Guarino da Verona',
      )

      ed = EntryDate.create!(entry: entry, observed_date: "ca. 1450-70")
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Latin'),
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'Italy, Ferrara'),
        uncertain_in_source: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: '17040000',
        comment: "Inscription on flyleaf",
        provenance_agent: Name.find_or_create_agent("Malfatti, Valeriano, Baron"),
        observed_name: 'Valeriano Malfatti Barone',
      )

      Provenance.create!(
        entry: entry,
        comment: 'Cites SDBM 11842',
        observed_name: 'European private collection',
      )

      entry
    end

    def create_entry_fourteen
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "14",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        folios: 381,
        num_lines: 46,
        num_columns: 2,
        height: 378,
        width: 260,
        initials_decorated: 179,
        manuscript_binding: 'Early 19th-century diced Russia leather over wooden boards.',
        other_info: 'Manuscript is dated in an inscription 30 December. 1480. Includes one full-length illuminated border.',
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 800000,
        currency: 'USD',
        sold: Sale::TYPE_SOLD_NO,
      )
      sale_agent = SaleAgent.create!(
        sale: sale,
        agent: @hill,
        role: SaleAgent::ROLE_SELLING_AGENT
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Quaestiones de potentia dei. Questiones de malo.',
        common_title: 'Confessions',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Thomas Aquinas, Saint')
      )

      ed = EntryDate.new(entry: entry, observed_date: '1480')
      ed.normalize_observed_date
      ed.save!

      EntryArtist.create!(
        entry: entry,
        artist: Name.find_or_create_artist('Matteo Felice')
      )

      EntryScribe.create!(
        entry: entry,
        scribe: Name.find_or_create_scribe('Crispus, Venceslaus')
      )

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Latin'),
        supplied_by_data_entry: true
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'Italy, Naples')
      )

      Provenance.create!(
        entry: entry,
        start_date: '14801230',
        comment: "Royal arms on first leaf.",
        provenance_agent: Name.find_or_create_agent("Ferdinand I of Aragon, King of Naples"),
      )

      Provenance.create!(
        entry: entry,
        acquisition_method: Provenance::TYPE_ACQUISITION_METHOD_BY_DESCENT,
        provenance_agent: Name.find_or_create_agent("Federico of Aragon"),
      )

      Provenance.create!(
        entry: entry,
        start_date: '15080000',
        comment: "Listed in inventory of his Chateau de Gaillon in 1508; his library.",
        observed_name: "Georges d'Amboise (1460-1510), Cardinal",
        provenance_agent: Name.find_or_create_agent("Amboise, Georges d'"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Archbishop's Library-Rouen"),
        acquisition_method: Provenance::TYPE_ACQUISITION_METHOD_BEQUEST
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Bourbon, Charles II de, Cardinal"),
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Bourbon, Charles III de, Cardinal"),
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Henry IV, King of France"),
        observed_name: "Henri IV, King of France (1589-1610)",
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Cabinet de Roi, King of France"),
      )

      Provenance.create!(
        entry: entry,
        start_date: "16040000",
        end_date: "1764000",
        comment: "Jesuits reclaimed the College de Clermont and its library, which included the manuscript, in 1604. Ownership inscription on fol. 1r. Another note, \"Paraphe au desir de l'arrest du 5 juillet 1763/Mesnil,\" referring tothe closing of the College following suppression of the order. No. 539 in 1764 College de Claremont sale.",
        provenance_agent: Name.find_or_create_agent("College de Clermont"),
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Meerman, Gerard"),
        observed_name: "Gerard Meerman (1722-71)",
        acquisition_method: Provenance::TYPE_ACQUISITION_METHOD_PURCHASE
      )

      Provenance.create!(
        entry: entry,
        start_date: "18240702",
        comment: "Sold in Part IV of sale, lot 480. Rebound.",
        provenance_agent: Name.find_or_create_agent("Meerman, Johan"),
        observed_name: "Meerman, Jean (1753-1815)",
      )

      Provenance.create!(
        entry: entry,
        comment: "No. 88 in his Catalogue of the Manuscripts at Ashburnham Place, Appendix, [1861].",
        provenance_agent: Name.find_or_create_agent("Ashburnham, Bertram, 4th Earl of Ashburnham"),
        observed_name: "Bertram, Fourth Early of Ashburnham (1797-1878)",
      )

      Provenance.create!(
        entry: entry,
        start_date: "1897000",
        acquisition_method: Provenance::TYPE_ACQUISITION_METHOD_PURCHASE,
        provenance_agent: Name.find_or_create_agent("Thompson, Henry Yates"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: "18990501",
        comment: "Lot 39.",
        provenance_agent: Name.find_or_create_agent("Sotheby's"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Emich, Gustave R. von"),
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("De Marinis, Tammaro"),
        observed_name: "Tammaro De Marinis (1878-1969)",
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: "19251130",
        comment: "Lot 355.",
        provenance_agent: Name.find_or_create_agent("Hoepli"),
      )

      Provenance.create!(
        entry: entry,
        comment: '"Two engraved bookplates were affixed to front pastedown: that of the Prince de Soragna (1773-1865), and a large 18th-century engraved armorial bookplate."',
        observed_name: "unidentified",
      )

      Provenance.create!(
        entry: entry,
        start_date: "19980623",
        comment: "According to catalog entry purchased by present owner in the 1980s in Lugano from a private collection.",
        provenance_agent: Name.find_or_create_agent("Sotheby's"),
        direct_transfer: true
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Kraus, H.P."),
      )

      entry
    end

  end

  class PennCatalog < RefDataBase
    def initialize
      create_source
      reindex create_entry_one
    end

    def create_source
      @upenn = Name.find_or_create_agent("University of Pennsylvania")
      @source = Source.create!(
        source_type: SourceType.collection_catalog,
        date: "1965",
        title: "Catalogue of Manuscripts in the Libraries of the University of Pennsylvania",
        author: "Norman P. Zacour and Rudolf Hirsch",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_LIBRARY,
        location_institution: "University of Pennsylvania Libraries",
        location: "Philadelphia, US",
        link: "Z6621 P44 cop. 2",
        created_by: lransom,
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: @upenn,
        role: SourceAgent::ROLE_INSTITUTION,
      )
    end

    def create_entry_one
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "Greek 1",
        transaction_type: Entry::TYPE_TRANSACTION_NONE,
        folios: 105,
        height: 205,
        width: 150,
        manuscript_binding: 'Contemporary (?) boards.',
        created_by: lransom,
        approved: true
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Addresses and letters',
      )
      EntryTitle.create!(
        entry: entry,
        title: 'Orations and letters',
      )
      EntryTitle.create!(
        entry: entry,
        title: 'Encomia',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Dokeianos, Ioannes'),
        observed_name: 'Ioannes Dokeianus (Johannes Docianus)',
      )
      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Gregoras, Nicephorus'),
      )
      EntryAuthor.create!(
        entry: entry,
        author: Name.find_or_create_author('Gregorios III, Patriarch of Constantinople'),
        observed_name: "Gregorios of Constantinople (Georgios of Cyprus)",
      )

      ed = EntryDate.new(entry: entry, observed_date: "16th cent.")
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Greek')
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Paper'
      )

      Provenance.create!(
        entry: entry,
        comment: "MS 51.",
        provenance_agent: Name.find_or_create_agent("Notre Dame of Pilar, Salamanca"),
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Lakon, Andreas Darmarios Epidaurios"),
      )

      entry
    end

  end

  class Pirages < RefDataBase

    def initialize
      create_source
      reindex create_entry_two
    end

    def create_source
      @pirages = Name.find_or_create_agent("Pirages")
      @source = Source.create!(
        source_type: SourceType.auction_catalog,
        date: "20150100",
        title: "Sampling of the illuminated material, incunabula, fine bindings, private press, plate books, early English works, and other interesting items we'll have on display at the 2015 California Antiquarian Book Fair.",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        location_institution: "Schoenberg Institute for Manuscript Studies",
        medium: Source::TYPE_MEDIUM_LIBRARY,
        created_by: lransom,
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: @pirages,
        role: SourceAgent::ROLE_SELLING_AGENT
      )
    end

    def create_entry_two
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "2",
        transaction_type: Entry::TYPE_TRANSACTION_SALE,
        height: 254,
        width: 210,
        initials_historiated: 1,
        initials_decorated: 19,
        manuscript_binding: 'Contemporary blind-stamped calf over wooden boards, four brass cornerplates, each with a long petal-like extension stamped with "Maria", complex central brass medallion with the Christogram "Y H S" against a radiating sun and with eight surrounding circles stamped with a starburst, one brass and leather clasp, brass catches for three other clasps (now lacking)',
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 45000,
        currency: 'USD',
        sold: Sale::TYPE_SOLD_UNKNOWN,
        sale_agents_attributes: [
          {
            agent: @pirages,
            role: SaleAgent::ROLE_SELLING_AGENT
          }
        ]
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Missale Secundum Morem Curie cum calendario',
        common_title: "Missal",
      )

      ed = EntryDate.new(entry: entry, observed_date: "first third of the 15th century")
      ed.normalize_observed_date
      ed.save!

      EntryArtist.create!(
        entry: entry,
        artist: Name.find_or_create_artist('Cortese, Cristoforo, style'),
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'Italy, Venice'),
      )

      Provenance.create!(
        entry: entry,
        provenance_agent: Name.find_or_create_agent("Monastery of San Giorgio Maggiore (Venice, Italy)"),
        observed_name: 'San Giorgio Maggiore',
        uncertain_in_source: true,
      )

      entry
    end

  end

  class DeRicci < RefDataBase

    def initialize
      create_source
      reindex create_saint_bernard_entry_one
      reindex create_allsop_entry_one
    end

    def create_source
      @source = Source.create!(
        source_type: SourceType.other_published,
        date: "19350000",
        title: "Census of Medieval and Renaissance Manuscrits in the United States and Canada, Vol. 1",
        author: "De Ricci, Seymour and Wilson, H. J.",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        date_accessed: "2015-03-10",
        location_institution: "University of Pennsylvania Libraries",
        location: "Philadelphia, US",
        link: "RBC Ref. Z 6620 U% R5 v. 1",
        medium: Source::TYPE_MEDIUM_LIBRARY,
        created_by: lransom,
      )
    end

    def create_saint_bernard_entry_one
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "1",
        transaction_type: Entry::TYPE_TRANSACTION_NONE,
        institution: Name.find_or_create_artist('Library of Saint Bernard College, Saint Bernard, Alabama'),
        folios: 192,
        height: 140,
        width: 100,
        miniatures_unspec_size: 9,
        manuscript_binding: '18th-century brown calf.',
        created_by: lransom,
        approved: true
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Horae',
        common_title: "Hours",
      )

      # TODO: source actually says "XVth c." but we don't yet support
      # parsing roman numerals
      ed = EntryDate.new(entry: entry, observed_date: "15th c.")
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Dutch')
      )

      EntryUse.create!(
        entry: entry,
        use: 'Utrecht',
      )

      entry
    end

    def create_allsop_entry_one
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "1",
        transaction_type: Entry::TYPE_TRANSACTION_NONE,
        institution: Name.find_or_create_artist('Allsopp, Fred W.'),
        created_by: lransom,
        approved: true
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Breviarium',
        common_title: "Breviary",
      )

      ed = EntryDate.new(entry: entry, observed_date: "ca. 1510")
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Latin')
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment',
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'England')
      )

      Provenance.create!(
        entry: entry,
        observed_name: 'not finished',
      )

      entry
    end

  end

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
        created_by: lransom,
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
        created_by: lransom,
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
        created_by: lransom,
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: Name.find_or_create_agent("Chiu, Jeff"),
        role: SourceAgent::ROLE_INSTITUTION,
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
        created_by: lransom,
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: Name.find_or_create_agent("Ebay"),
        role: SourceAgent::ROLE_SELLING_AGENT,
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
        manuscript_binding: 'Original wooden boards',
        manuscript_link: "http://www.ebay.com/itm/MEDIEVAL-Miniature-CRUCIFIXION-c1450-A-D-Book-of-Hours-Vellum-MISSAL-MANUSCRIPT-/371277701327?pt=LH_DefaultDomain_0&hash=item5671e020cf",
        other_info: "This is a fragment. Folio count not provided.",
        created_by: lransom,
        approved: true
      )

      sale = Sale.create!(
        entry: entry,
        price: 3299.0,
        currency: 'USD',
        sold: Sale::TYPE_SOLD_UNKNOWN,
      )
      SaleAgent.create!(
        sale: sale,
        agent: Name.find_or_create_agent("Ebay"),
        role: SaleAgent::ROLE_SELLING_AGENT
      )
      SaleAgent.create!(
        sale: sale,
        # TODO: we need a way to indicate this is an ebay account name in the Name record
        agent: Name.find_or_create_agent("weisse-lilie-art"),
        role: SaleAgent::ROLE_SELLER_OR_HOLDER
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Book of Hours or Missal, fragment',
      )

      ed = EntryDate.new(entry: entry, observed_date: 'about 1450 A.D.')
      ed.normalize_observed_date
      ed.save!

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'France'),
      )

      Provenance.create!(
        entry: entry,
        comment: "Inscription on a leaf: Missale m S. P. Sharrock Ushaw. [Ushaw is possible reference to Ushaw College, Durham University?].",
        observed_name: "S. P. Sharrock Ushaw",
      )

      Comment.create!(
        comment: "A google search on \"sharrock ushaw\" returned a website from Ushaw College Library Special Collections Catalogue. The Ushaw College History Papers archive contains this reference: UC/H306 13 November 1815 Letter from J.B. Marsh to William Hogarth: financial affairs of P.J. Sharrock, and the offer of his books to Ushaw's library. (see http://reed.dur.ac.uk/xtf/view?docId=ead/ush/uchistor.xml).",
        created_at: DateTime.now,
        created_by_id: lransom.id,
        entry_comments_attributes: [
          {
            entry: entry,
          }
        ]
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
        created_by: lransom,
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: Name.find_or_create_agent("Marc Van de Wiele"),
        role: SourceAgent::ROLE_SELLING_AGENT,
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
        #comments: "Spreadsheet created and shared by curators at David Rubenstein Library, Duke University.",
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: Name.find_or_create_agent("Duke University, David Rubenstein Library"),
        role: SourceAgent::ROLE_INSTITUTION,
      )
    end

    def create_entry
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "Greek MS 001",
        transaction_type: Entry::TYPE_TRANSACTION_NONE,
        institution: Name.find_or_create_agent("Duke University, David Rubenstein Library"),
        folios: 198,
        num_lines: 41,
        num_columns: 1,
        height: 306,
        width: 227,
        manuscript_binding: 'Clam-shell box',
        other_info: "Complete New Testament in Greek. Order of Books:  Gospels, Acts, James, Pauline Epistles, general epistles except for James, Apocalypse. Gregory-Aland 1780.",
        created_by: lransom,
        approved: true
      )

      EntryTitle.create!(
        entry: entry,
        title: 'New Testament',
      )

      ed = EntryDate.new(entry: entry, observed_date: '1200')
      ed.normalize_observed_date
      ed.save!

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Greek')
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
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
        title: '"A Catalogue of Medieval and Renaissance Manuscripts Located at Villanova University," Manuscripta, vol. 57:2',
        author: "Kenneth B. Steinhauser",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        medium: Source::TYPE_MEDIUM_LIBRARY,
        date_accessed: "20150323",
        location_institution: "University of Pennsylvania Libraries",
        location: "Philadelphia, PA",
        created_by: lransom,
      )
    end

    def create_entry
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "OM 1",
        transaction_type: Entry::TYPE_TRANSACTION_NONE,
        institution: Name.find_or_create_agent("Villanova University, Falvey Memorial Library"),
        folios: 212,
        num_lines: 26,
        num_columns: 1,
        height: 96,
        width: 56,
        initials_decorated: 1,
        manuscript_binding: 'modern light brown inlaid morocco with red and gold floral and leaf decoration',
        created_by: lransom,
        approved: true
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Opera minora',
      )

      EntryAuthor.create!(
        entry: entry,
        observed_name: "(pseudo-) Augustine",
        author: Name.find_or_create_author('Pseudo-Augustine, Saint, Bishop of Hippo')
      )

      ed = EntryDate.new(entry: entry, observed_date: "14th century")
      ed.normalize_observed_date
      ed.save!

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
      )

      Provenance.create!(
        entry: entry,
        comment: '"E.H." is an unknown 19th century or early 20th century owner.',
        observed_name: "E.H.",
      )

      Provenance.create!(
        entry: entry,
        comment: 'Provenance info given in De Ricci, II: 2132.',
        provenance_agent: Name.find_or_create_agent("Leighton, W. J."),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        start_date: "19181114",
        comment: 'Provenance info given in De Ricci, II: 2132.',
        provenance_agent: Name.find_or_create_agent("Sotheby's"),
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        comment: 'Provenance info given in De Ricci, II: 2132.',
        provenance_agent: Name.find_or_create_agent("James Tregaskis (Firm)"),
        observed_name: "James Tregaskis",
        direct_transfer: true,
      )

      Provenance.create!(
        entry: entry,
        comment: 'Provenance info given in De Ricci, II: 2132.',
        provenance_agent: Name.find_or_create_agent("John F. Lewis"),
        direct_transfer: true
      )

      Provenance.create!(
        entry: entry,
        comment: 'Provenance info given in De Ricci, II: 2132.',
        provenance_agent: Name.find_or_create_agent("Villanova College")
      )

      entry
    end

  end

end
