require "rails_helper"

RSpec.describe Entry, type: :model do
  let(:admin)  { create(:admin) }
  let(:source) { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
  let(:entry)  { Entry.create!(source: source, created_by: admin) }

  before do
    allow(Sunspot).to receive(:index)
    allow(Sunspot).to receive(:remove)
  end

  # ---------------------------------------------------------------------------
  # Validations
  # ---------------------------------------------------------------------------
  describe "validations" do
    it "requires source" do
      e = Entry.new
      expect(e).not_to be_valid
      expect(e.errors[:source]).to be_present
    end

    it "rejects non-numeric folios" do
      e = Entry.new(source: source, folios: "abc")
      expect(e).not_to be_valid
    end

    it "allows nil folios" do
      e = Entry.new(source: source, folios: nil)
      e.valid?
      expect(e.errors[:folios]).to be_empty
    end

    it "rejects invalid alt_size" do
      e = Entry.new(source: source, alt_size: "XL")
      expect(e).not_to be_valid
      expect(e.errors[:alt_size]).to be_present
    end

    it "accepts valid alt_size" do
      e = Entry.new(source: source, alt_size: "F")
      e.valid?
      expect(e.errors[:alt_size]).to be_empty
    end

    it "rejects manuscript_binding over 1024 chars" do
      e = Entry.new(source: source, manuscript_binding: "x" * 1025)
      expect(e).not_to be_valid
      expect(e.errors[:manuscript_binding]).to be_present
    end

    describe "transaction_type validation" do
      it "rejects transaction_type not in the valid list" do
        e = Entry.new(source: source, transaction_type: "barter")
        expect(e).not_to be_valid
        expect(e.errors[:transaction_type]).to be_present
      end

      it "accepts a valid transaction_type" do
        e = Entry.new(source: source, transaction_type: Entry::TYPE_TRANSACTION_SALE)
        e.valid?
        expect(e.errors[:transaction_type]).to be_empty
      end
    end
  end

  # ---------------------------------------------------------------------------
  # Callbacks
  # ---------------------------------------------------------------------------
  describe "after_create :update_source_status" do
    it "updates source from To Be Entered to Partially Entered on first entry" do
      source.update_column(:status, Source::TYPE_STATUS_TO_BE_ENTERED)
      Entry.create!(source: source, created_by: admin)
      expect(source.reload.status).to eq(Source::TYPE_STATUS_PARTIALLY_ENTERED)
    end

    it "does not change source status when status is not To Be Entered" do
      source.update_column(:status, Source::TYPE_STATUS_ENTERED)
      Entry.create!(source: source, created_by: admin)
      expect(source.reload.status).to eq(Source::TYPE_STATUS_ENTERED)
    end
  end

  # ---------------------------------------------------------------------------
  # Public ID
  # ---------------------------------------------------------------------------
  describe "#public_id" do
    it "returns a string containing the entry id" do
      expect(entry.public_id).to be_a(String)
      expect(entry.public_id).to include(entry.id.to_s)
    end
  end

  # ---------------------------------------------------------------------------
  # display_value / to_s
  # ---------------------------------------------------------------------------
  describe "#display_value" do
    it "joins entry title strings" do
      EntryTitle.create!(entry: entry, title: "Gospel of Mark", order: 1)
      expect(entry.display_value).to eq("Gospel of Mark")
    end

    it "returns empty string when no titles" do
      expect(entry.display_value).to eq("")
    end
  end

  describe "#to_s" do
    it "delegates to display_value" do
      expect(entry.to_s).to eq(entry.display_value)
    end
  end

  # ---------------------------------------------------------------------------
  # manuscript / get_entries_for_manuscript
  # ---------------------------------------------------------------------------
  describe "#manuscript" do
    it "returns nil when no entry_manuscript" do
      expect(entry.manuscript).to be_nil
    end

    it "returns the manuscript for IS-type link" do
      ms = Manuscript.create!(created_by: admin)
      EntryManuscript.create!(
        entry: entry, manuscript: ms,
        relation_type: EntryManuscript::TYPE_RELATION_IS,
        created_by: admin, updated_by: admin
      )
      expect(entry.manuscript).to eq(ms)
    end
  end

  describe "#get_entries_for_manuscript" do
    it "returns empty array when no manuscript" do
      expect(entry.get_entries_for_manuscript).to eq([])
    end

    it "returns sibling entries for linked manuscript" do
      ms = Manuscript.create!(created_by: admin)
      other = Entry.create!(source: source, created_by: admin)
      EntryManuscript.create!(entry: entry, manuscript: ms, relation_type: "is", created_by: admin, updated_by: admin)
      EntryManuscript.create!(entry: other, manuscript: ms, relation_type: "is", created_by: admin, updated_by: admin)
      entries = entry.get_entries_for_manuscript
      expect(entries).to include(entry, other)
    end
  end

  # ---------------------------------------------------------------------------
  # Sale helpers
  # ---------------------------------------------------------------------------
  describe "sale helpers" do
    context "when no sale exists" do
      it "#get_sale returns nil" do
        expect(entry.get_sale).to be_nil
      end

      it "#get_sale_sold returns nil" do
        expect(entry.get_sale_sold).to be_nil
      end

      it "#get_sale_price returns nil" do
        expect(entry.get_sale_price).to be_nil
      end

      it "#get_sale_agents_names returns empty string for any role" do
        expect(entry.get_sale_agents_names(SaleAgent::ROLE_SELLING_AGENT)).to eq("")
      end
    end

    context "when a sale exists" do
      let!(:sale) { Sale.create!(entry: entry, sold: "Yes", price: 100.0) }
      let(:agent) { Name.create!(name: "Christie's", is_provenance_agent: true, created_by: admin, updated_by: admin) }

      before do
        SaleAgent.create!(sale: sale, agent: agent, role: SaleAgent::ROLE_SELLING_AGENT)
      end

      it "#get_sale returns the sale" do
        expect(entry.get_sale).to eq(sale)
      end

      it "#sale returns the sale" do
        expect(entry.sale).to eq(sale)
      end

      it "#get_sale_sold returns sold value" do
        expect(entry.get_sale_sold).to eq("Yes")
      end

      it "#get_sale_price returns price" do
        expect(entry.get_sale_price).to eq(100.0)
      end

      it "#get_sale_selling_agents_names returns agent display" do
        result = entry.get_sale_selling_agents_names
        expect(result).to be_a(String)
      end

      it "#get_sale_sellers_or_holders_names returns empty when none" do
        expect(entry.get_sale_sellers_or_holders_names).to eq("")
      end

      it "#get_sale_buyers_names returns empty when none" do
        expect(entry.get_sale_buyers_names).to eq("")
      end

      it "#sale_agent returns agents for role" do
        result = entry.sale_agent(SaleAgent::ROLE_SELLING_AGENT)
        expect(result).to include(agent)
      end

      it "#sale_agent returns nil for role with no agents" do
        result = entry.sale_agent(SaleAgent::ROLE_BUYER)
        expect(result).to be_blank
      end
    end
  end

  # ---------------------------------------------------------------------------
  # missing_authority_names
  # ---------------------------------------------------------------------------
  describe "#missing_authority_names" do
    it "returns 0 for entry with no associations" do
      expect(entry.missing_authority_names).to eq(0)
    end

    it "counts entry_authors with observed_name but no author_id" do
      EntryAuthor.create!(entry: entry, observed_name: "Unknown Author", order: 1)
      expect(entry.missing_authority_names).to eq(1)
    end

    it "does not count entry_authors that have an author_id" do
      author = Name.create!(name: "Known Author", is_author: true, created_by: admin, updated_by: admin)
      EntryAuthor.create!(entry: entry, author: author, observed_name: "Known Author", order: 1)
      expect(entry.missing_authority_names).to eq(0)
    end
  end

  # ---------------------------------------------------------------------------
  # provenance_names
  # ---------------------------------------------------------------------------
  describe "#provenance_names" do
    it "returns empty array when no provenance" do
      expect(entry.provenance_names).to eq([])
    end

    it "includes agent names and observed names" do
      agent = Name.create!(name: "ZzzTestAgent", is_provenance_agent: true, created_by: admin, updated_by: admin)
      Provenance.create!(entry: entry, provenance_agent: agent, observed_name: "ZzzObserved", order: 1)
      names = entry.provenance_names
      expect(names).to include("ZzzTestAgent")
      expect(names).to include("ZzzObserved")
    end

    it "includes only observed_name when no agent" do
      Provenance.create!(entry: entry, observed_name: "Anonymous", order: 1)
      expect(entry.provenance_names).to include("Anonymous")
    end
  end

  # ---------------------------------------------------------------------------
  # unique_provenance_agents
  # ---------------------------------------------------------------------------
  describe "#unique_provenance_agents" do
    it "returns empty array when no provenance" do
      expect(entry.unique_provenance_agents).to eq([])
    end

    it "deduplicates agents" do
      agent = Name.create!(name: "ZzzTestAgent", is_provenance_agent: true, created_by: admin, updated_by: admin)
      Provenance.create!(entry: entry, provenance_agent: agent, order: 1)
      Provenance.create!(entry: entry, provenance_agent: agent, order: 2)
      expect(entry.unique_provenance_agents.length).to eq(1)
    end

    it "includes entries keyed by observed_name when no agent" do
      Provenance.create!(entry: entry, observed_name: "Anonymous Buyer", order: 1)
      agents = entry.unique_provenance_agents
      expect(agents.map { |a| a[:name] }).to include("Anonymous Buyer")
    end
  end

  # ---------------------------------------------------------------------------
  # as_flat_hash
  # ---------------------------------------------------------------------------
  describe "#as_flat_hash" do
    it "returns a Hash with expected keys" do
      hash = entry.as_flat_hash
      expect(hash).to be_a(Hash)
      expect(hash).to have_key(:id)
      expect(hash).to have_key(:titles)
      expect(hash).to have_key(:authors)
      expect(hash).to have_key(:deprecated)
    end

    it "includes csv coordinates key when options[:csv] is set" do
      hash = entry.as_flat_hash(options: { csv: true })
      expect(hash).to have_key(:coordinates)
    end
  end

  # ---------------------------------------------------------------------------
  # bookmark_details
  # ---------------------------------------------------------------------------
  describe "#bookmark_details" do
    it "returns a Hash with humanized keys" do
      details = entry.bookmark_details
      expect(details).to be_a(Hash)
      # Only non-blank values are included
      details.keys.each { |k| expect(k).to be_a(String) }
    end
  end

  # ---------------------------------------------------------------------------
  # create_activity
  # ---------------------------------------------------------------------------
  describe "#create_activity" do
    it "does not create activity for draft entries" do
      draft_entry = Entry.create!(source: source, draft: true, created_by: admin)
      expect { draft_entry.create_activity("create", admin, nil) }
        .not_to change(Activity, :count)
    end

    it "creates activity for non-draft entries" do
      expect { entry.create_activity("create", admin, nil) }
        .to change(Activity, :count).by(1)
    end
  end

  # ---------------------------------------------------------------------------
  # decrement_counters
  # ---------------------------------------------------------------------------
  describe "#decrement_counters" do
    it "decrements source entries_count" do
      Source.reset_counters(source.id, :entries)
      entry # ensure persisted
      initial = source.reload.entries_count
      allow(entry).to receive(:manuscripts).and_return([])
      entry.decrement_counters
      expect(source.reload.entries_count).to eq(initial - 1)
    end
  end

  # ---------------------------------------------------------------------------
  # Class methods
  # ---------------------------------------------------------------------------
  describe ".filters" do
    it "returns an array of filter pairs" do
      expect(Entry.filters).to be_an(Array)
      expect(Entry.filters.first).to be_an(Array)
    end
  end

  describe ".fields" do
    it "returns an array of field pairs" do
      expect(Entry.fields).to be_an(Array)
      expect(Entry.fields.first).to be_an(Array)
    end
  end

  describe ".dates" do
    it "returns created_at and updated_at" do
      keys = Entry.dates.map(&:last)
      expect(keys).to include("created_at", "updated_at")
    end
  end

  describe ".search_fields" do
    it "excludes Deprecated and Draft pairs from filters" do
      sf = Entry.search_fields
      expect(sf).not_to include(["Deprecated", "deprecated"])
      expect(sf).not_to include(["Draft", "draft"])
    end
  end

  describe ".similar_fields" do
    it "returns an array of symbols" do
      expect(Entry.similar_fields).to be_an(Array)
      expect(Entry.similar_fields.first).to be_a(Symbol)
    end
  end

  # ---------------------------------------------------------------------------
  # Scopes
  # ---------------------------------------------------------------------------
  describe ".approved_only" do
    it "returns only approved entries" do
      approved = Entry.create!(source: source, approved: true, created_by: admin)
      unapproved = Entry.create!(source: source, approved: false, created_by: admin)
      results = Entry.approved_only
      expect(results).to include(approved)
      expect(results).not_to include(unapproved)
    end
  end

  describe ".with_author" do
    it "returns entries that have the given author" do
      author = Name.create!(name: "Zzz WithAuthor", is_author: true, created_by: admin, updated_by: admin)
      EntryAuthor.create!(entry: entry, author: author, order: 1)
      other = Entry.create!(source: source, created_by: admin)

      results = Entry.with_author(author)
      expect(results).to include(entry)
      expect(results).not_to include(other)
    end
  end

  describe ".most_recent" do
    it "returns the N most recent entries" do
      3.times { Entry.create!(source: source, created_by: admin) }
      expect(Entry.most_recent(2).length).to eq(2)
    end
  end
end
