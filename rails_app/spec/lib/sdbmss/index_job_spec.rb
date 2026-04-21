require "rails_helper"

describe SDBMSS::IndexJob do

  let(:logger) { instance_double(Logger, info: nil, error: nil) }
  let(:job)    { described_class.new }

  let(:admin)  { create(:admin) }
  let(:source) { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
  let(:entry)  { Entry.create!(source: source, created_by: admin) }
  let(:name) do
    n = Name.create!(name: "IndexJobTestAuthor", is_author: true, created_by: admin)
    EntryAuthor.create!(entry: entry, author: n)
    n
  end

  before do
    allow(Delayed::Worker).to receive(:logger).and_return(logger)
    allow(Sunspot).to receive(:index)
  end

  describe "#perform" do
    context "when model_class_str is 'Entry'" do
      it "indexes entries directly and logs start/finish" do
        expect(Sunspot).to receive(:index).at_least(:once)
        expect(logger).to receive(:info).with(/Starting reindex of Entry/)
        expect(logger).to receive(:info).with(/Finished reindex of/)
        job.perform("Entry", [entry.id])
      end
    end

    context "when model_class_str responds to entries_to_index_on_update" do
      it "indexes via the associated model and logs start/finish" do
        expect(Sunspot).to receive(:index).at_least(:once)
        expect(logger).to receive(:info).with(/Starting reindex of Name/)
        expect(logger).to receive(:info).with(/Finished reindex of/)
        job.perform("Name", [name.id])
      end
    end

    context "when model_class_str has no entries_to_index_on_update" do
      it "logs an error and does not call Sunspot.index" do
        expect(Sunspot).not_to receive(:index)
        expect(logger).to receive(:error).with(/isn't indexable/)
        job.perform("User", [admin.id])
      end
    end
  end

  describe "#index_entries" do
    context "when passed an ActiveRecord::Relation (responds to find_in_batches)" do
      it "batches via find_in_batches and calls Sunspot.index" do
        relation = Entry.where(id: entry.id)
        expect(Sunspot).to receive(:index).at_least(:once)
        job.index_entries(relation)
      end
    end

    context "when passed a plain Array" do
      it "calls Sunspot.index directly with the array" do
        arr = [entry]
        expect(Sunspot).to receive(:index).with(arr)
        job.index_entries(arr)
      end
    end
  end

end
