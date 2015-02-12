
# This is a library that creates "reference data", containing entries
# from actual catalogs.
#
# The purpose of this is to verify we can properly store all types of
# entries, and to keep a normative record of the fields where various
# bits of data should live, since this is not always obvious or easy
# to remember for the many types of sources and entries.
#
# Think of this as an "integration test" of all our models as a
# organic whole.
#
# This gets called via rspec for testing, and also in development
# to re-create data in case we want to examine something.

module SDBMSS::ReferenceData

  class << self
    def create_all
      JonathanHill.new
      PennCatalog.new
    end
  end

  class JonathanHill

    def initialize
      create_source
      create_entry_one
      create_entry_fourteen
    end

    def create_source
      @hill = Agent.find_or_create_by(name: "Jonathan A. Hill")
      @source = Source.create!(
        source_type: Source::TYPE_AUCTION_CATALOG,
        date: "20150101",
        title: "Catalogue 213: Fine and Important Manuscripts and Printed Books",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        link: "https://www.jonathanahill.com/lists/HomePageFiles/Cat%20213%20unillustrated%20proofs.pdf",
        cataloging_type: "pdf",
        created_by: User.where(username: 'lransom').first,
      )

      source_agent = SourceAgent.create!(
        source: @source,
        agent: @hill,
        role: SourceAgent::ROLE_SELLER_AGENT
      )
    end

    def create_entry_one
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "1",
        folios: 166,
        num_columns: 2,
        height: 255,
        width: 185,
        initials_decorated: 15,
        manuscript_binding: 'Ca. 1900, with the gilt stamp of "L. Broca" (Lucien Broca), red morocco over pasteboard, upper and lower cover with gilt double fillet borders enclosing a gilt central medallion; five raised bands on spine, compartments repeating gilt motif, edges and turn-ins gilt.',
        created_by: User.where(username: 'lransom').first,
      )

      transaction = Event.create!(
        primary: true,
        entry: entry,
        price: 270000,
        currency: 'USD',
        sold: Event::TYPE_SOLD_NO,
      )
      transaction_agent = EventAgent.create!(
        event: transaction,
        agent: @hill,
        role: EventAgent::ROLE_SELLER_AGENT
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
        author: Author.find_or_create_by(name: 'Augustine, Saint, Bishop of Hippo')
      )

      EntryAuthor.create!(
        entry: entry,
        author: Author.find_or_create_by(name: 'Pseudo-Augustine, Saint, Bishop of Hippo'),
        observed_name: 'Pseudo-Augustine'
      )

      EntryAuthor.create!(
        entry: entry,
        author: Author.find_or_create_by(name: 'Valerius, Bishop of Hippo')
      )

      EntryDate.create!(entry: entry, date: '1425', circa: 'C2Q')

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

      Event.create!(
        entry: entry,
        start_date: '19220700',
        comment: "Bookplate. His sale Sotheby's, July 1922 (day of sale not given), lot. 1027.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Sotheby's"),
            role: EventAgent::ROLE_SELLER_AGENT
          },
          {
            agent: Agent.find_or_create_by(name: "Tomkinson, Michael"),
            observed_name: "Michael Tomkinson",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        comment: "Bookplate.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Ritman, J. R."),
            observed_name: "Bibliotheca Philosophica Hermetica, J. R. Ritman, Amsterdam",
            role: EventAgent::ROLE_SELLER_OR_HOLDER,
          },
          {
            observed_name: "European private collection",
            role: EventAgent::ROLE_SELLER_OR_HOLDER,
          }
        ]
      )

    end

    def create_entry_fourteen
      entry = Entry.create!(
        source: @source,
        catalog_or_lot_number: "14",
        folios: 381,
        num_lines: 46,
        num_columns: 2,
        height: 378,
        width: 260,
        initials_decorated: 179,
        manuscript_binding: 'Early 19th-century diced Russia leather over wooden boards.',
        other_info: 'Manuscript is dated in an inscription 30 December. 1480. Includes one full-length illuminated border.',
        created_by: User.where(username: 'lransom').first,
      )

      transaction = Event.create!(
        primary: true,
        entry: entry,
        price: 800000,
        currency: 'USD',
        sold: Event::TYPE_SOLD_NO,
      )
      transaction_agent = EventAgent.create!(
        event: transaction,
        agent: @hill,
        role: EventAgent::ROLE_SELLER_AGENT
      )

      EntryTitle.create!(
        entry: entry,
        title: 'Quaestiones de potentia dei. Questiones de malo.',
        common_title: 'Confessions',
      )

      EntryAuthor.create!(
        entry: entry,
        author: Author.find_or_create_by(name: 'Thomas Aquinas, Saint')
      )

      EntryDate.create!(entry: entry, date: '1480')

      EntryArtist.create!(
        entry: entry,
        artist: Artist.find_or_create_by(name: 'Matteo Felice')
      )

      EntryScribe.create!(
        entry: entry,
        scribe: Scribe.find_or_create_by(name: 'Crispus, Venceslaus')
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

      Event.create!(
        entry: entry,
        start_date: '14801230',
        comment: "Royal arms on first leaf.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Ferdinand I of Aragon, King of Naples"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Federico of Aragon"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: '15080000',
        comment: "Listed in inventory of his Chateau de Gaillon in 1508; his library.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Amboise, Georges d'"),
            observed_name: "Georges d'Amboise (1460-1510), Cardinal",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          },
          {
            agent: Agent.find_or_create_by(name: "Archbishop's Library-Rouen"),
            role: EventAgent::ROLE_BUYER
          },
        ]
      )

      Event.create!(
        entry: entry,
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Bourbon, Charles II de, Cardinal"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Bourbon, Charles III de, Cardinal"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          },
          {
            agent: Agent.find_or_create_by(name: "Henry IV, King of France"),
            observed_name: "Henri IV, King of France (1589-1610)",
            role: EventAgent::ROLE_BUYER,
          }
        ]
      )

      Event.create!(
        entry: entry,
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Henry IV, King of France"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          },
          {
            agent: Agent.find_or_create_by(name: "Cabinet de Roi, King of France"),
            role: EventAgent::ROLE_BUYER,
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: "16040000",
        end_date: "1764000",
        comment: "Jesuits reclaimed the College de Clermont and its library, which included the manuscript, in 1604. Ownership inscription on fol. 1r. Another note, \"Paraphe au desir de l'arrest du 5 juillet 1763/Mesnil,\" referring tothe closing of the College following suppression of the order. No. 539 in 1764 College de Claremont sale.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "College de Clermont"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          },
          {
            agent: Agent.find_or_create_by(name: "Meerman, Gerard"),
            observed_name: "Gerard Meerman (1722-71)",
            role: EventAgent::ROLE_BUYER
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: "17640000",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Meerman, Gerard"),
            observed_name: "Gerard Meerman (1722-71)",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: "18240702",
        comment: "Sold in Part IV of sale, lot 480. Rebound.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Meerman, Johan"),
            observed_name: "Meerman, Jean (1753-1815)",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        comment: "No. 88 in his Catalogue of the Manuscripts at Ashburnham Place, Appendix, [1861].",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Ashburnham, Bertram, 4th Earl of Ashburnham"),
            observed_name: "Bertram, Fourth Early of Ashburnham (1797-1878)",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: "1897000",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Thompson, Henry Yates"),
            role: EventAgent::ROLE_BUYER
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: "18990501",
        comment: "Lot 39.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Sotheby's"),
            role: EventAgent::ROLE_SELLER_AGENT
          },
          {
            agent: Agent.find_or_create_by(name: "Thompson, Henry Yates"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          },
          {
            agent: Agent.find_or_create_by(name: "Emich, Gustave R. von"),
            role: EventAgent::ROLE_BUYER,
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: "19251130",
        comment: "Lot 355.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "De Marinis, Tammaro"),
            observed_name: "Tammaro De Marinis (1878-1969)",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        comment: '"Two engraved bookplates were affixed to front pastedown: that of the Prince de Soragna (1773-1865), and a large 18th-century engraved armorial bookplate."',
        event_agents_attributes: [
          {
            observed_name: "unidentified",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        start_date: "19980623",
        comment: "According to catalog entry purchased by present owner in the 1980s in Lugano from a private collection.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Sotheby's"),
            role: EventAgent::ROLE_SELLER_AGENT
          },
          {
            observed_name: "Anonymous",
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          },
          {
            agent: Agent.find_or_create_by(name: "Kraus, H.P."),
            role: EventAgent::ROLE_BUYER
          }
        ]
      )

    end

  end

  class PennCatalog
    def initialize
      create_source
      create_entry_one
    end

    def create_source
      @upenn = Agent.find_or_create_by(name: "University of Pennsylvania")
      @source = Source.create!(
        source_type: Source::TYPE_COLLECTION_CATALOG,
        date: "1965",
        title: "Catalogue of Manuscripts in the Libraries of the University of Pennsylvania",
        author: "Norman P. Zacour and Rudolf Hirsch",
        whether_mss: Source::TYPE_HAS_MANUSCRIPT_YES,
        current_location: "University of Pennsylvania Libraries",
        location_city: "Philadelphia",
        location_country: "US",
        link: "Z6621 P44 cop. 2",
        cataloging_type: "print",
        created_by: User.where(username: 'lransom').first,
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
        folios: 105,
        height: 205,
        width: 150,
        manuscript_binding: 'Contemporary (?) boards.',
        created_by: User.where(username: 'lransom').first,
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
        author: Author.find_or_create_by(name: 'Dokeianos, Ioannes'),
        observed_name: 'Ioannes Dokeianus (Johannes Docianus)',
      )
      EntryAuthor.create!(
        entry: entry,
        author: Author.find_or_create_by(name: 'Gregoras, Nicephorus'),
      )
      EntryAuthor.create!(
        entry: entry,
        author: Author.find_or_create_by(name: 'Gregorios III, Patriarch of Constantinople'),
        observed_name: "Gregorios of Constantinople (Georgios of Cyprus)",
      )

      EntryDate.create!(entry: entry, date: '1550', circa: 'CCENT')

      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: 'Greek')
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Paper'
      )

      Event.create!(
        entry: entry,
        comment: "MS 51.",
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Notre Dame of Pilar, Salamanca"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

      Event.create!(
        entry: entry,
        event_agents_attributes: [
          {
            agent: Agent.find_or_create_by(name: "Lakon, Andreas Darmarios Epidaurios"),
            role: EventAgent::ROLE_SELLER_OR_HOLDER
          }
        ]
      )

    end

  end

end
