
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
        manuscript_binding: 'Ca. 1900, with the gilt stamp of "L. Broca" (Lucien Broca), red morocco over pasteboard, upper and lower cover with gilt double fillet borders enclosing a gilt central medallion; five raised bands on spine, compartments repeating gilt motif, edges and turn-ins gilt.'
      )

      transaction = Event.create!(
        primary: true,
        entry: entry,
        price: 270000,
        currency: 'USD',
        sold: 'NO'
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

      # TODO: account for ? using flag
      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'Italy, Tuscany, Florence?')
      )

      provenance1 = Event.create!(
        entry: entry,
        end_date: '19220700',
        comment: "Bookplate. His sale Sotheby's, July 1922 (day of sale not given), lot. 1027."
      )
      EventAgent.create!(
        event: provenance1,
        agent: Agent.find_or_create_by(name: "Sotheby's"),
        role: EventAgent::ROLE_SELLER_AGENT
      )
      EventAgent.create!(
        event: provenance1,
        agent: Agent.find_or_create_by(name: "Tomkinson, Michael"),
        observed_name: "Michael Tomkinson",
        role: EventAgent::ROLE_SELLER_OR_HOLDER
      )

      provenance2 = Event.create!(
        entry: entry,
        comment: "Bookplate.",
      )
      EventAgent.create!(
        event: provenance2,
        agent: Agent.find_or_create_by(name: "Ritman, J. R."),
        observed_name: "Bibliotheca Philosophica Hermetica, J. R. Ritman, Amsterdam",
        role: EventAgent::ROLE_SELLER_OR_HOLDER,
      )

      provenance3 = Event.create!(
        entry: entry
      )
      EventAgent.create!(
        event: provenance3,
        observed_name: "European private collection",
        role: EventAgent::ROLE_SELLER_OR_HOLDER,
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
      )

      transaction = Event.create!(
        primary: true,
        entry: entry,
        price: 800000,
        currency: 'USD',
        sold: 'NO'
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

      # TODO
      EntryLanguage.create!(
        entry: entry,
        language: Language.find_or_create_by(name: '[Latin]')
      )

      EntryMaterial.create!(
        entry: entry,
        material: 'Parchment'
      )

      EntryPlace.create!(
        entry: entry,
        place: Place.find_or_create_by(name: 'Italy, Naples')
      )

      provenance1 = Event.create!(
        entry: entry,
        acquire_date: '14801230',
        comment: "Royal arms on first leaf."
      )
      EventAgent.create!(
        event: provenance1,
        agent: Agent.find_or_create_by(name: "Ferdinand I of Aragon, King of Naples"),
        role: EventAgent::ROLE_SELLER_OR_HOLDER
      )

      provenance2 = Event.create!(
        entry: entry
      )
      EventAgent.create!(
        event: provenance2,
        agent: Agent.find_or_create_by(name: "Federico of Aragon"),
        role: EventAgent::ROLE_SELLER_OR_HOLDER
      )

      provenance3 = Event.create!(
        entry: entry,
        acquire_date: '1508',
        comment: "Listed in inventory of 1508.",
      )
      EventAgent.create!(
        event: provenance3,
        agent: Agent.find_or_create_by(name: "Amboise, Georges d'"),
        role: EventAgent::ROLE_SELLER_OR_HOLDER
      )

    end

  end

end
