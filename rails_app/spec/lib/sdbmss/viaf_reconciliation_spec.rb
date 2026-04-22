require "rails_helper"
require "csv"

RSpec.describe SDBMSS::VIAFReconciliation do
  # ---------------------------------------------------------------------------
  # .write_file
  # ---------------------------------------------------------------------------
  describe ".write_file" do
    it "writes name/viaf_id pairs to a CSV file" do
      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.write_file({ "Smith, John" => "12345", "Doe, Jane" => "67890" }, f.path)
        rows = CSV.read(f.path)
        expect(rows).to contain_exactly(["Smith, John", "12345"], ["Doe, Jane", "67890"])
      end
    end

    it "writes an empty file when given empty hash" do
      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.write_file({}, f.path)
        expect(CSV.read(f.path)).to eq([])
      end
    end
  end

  # ---------------------------------------------------------------------------
  # .update_names
  # ---------------------------------------------------------------------------
  describe ".update_names" do
    let(:admin) { create(:admin) }

    it "sets viaf_id on matching Name records that have none" do
      name = Name.create!(name: "Testauthor", is_author: true, created_by: admin, updated_by: admin)
      expect(name.viaf_id).to be_nil

      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.write_file({ "Testauthor" => "99999" }, f.path)
        described_class.update_names(f.path)
      end

      expect(name.reload.viaf_id).to eq("99999")
    end

    it "skips names with viaf_id already set" do
      name = Name.create!(name: "Existingauthor", viaf_id: "11111", is_author: true, created_by: admin, updated_by: admin)

      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.write_file({ "Existingauthor" => "22222" }, f.path)
        described_class.update_names(f.path)
      end

      expect(name.reload.viaf_id).to eq("11111")
    end

    it "skips rows where viaf_id is -1 (no match found)" do
      name = Name.create!(name: "Unmatched", is_author: true, created_by: admin, updated_by: admin)

      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.write_file({ "Unmatched" => "-1" }, f.path)
        described_class.update_names(f.path)
      end

      expect(name.reload.viaf_id).to be_nil
    end

    it "handles rows where Name is not in database" do
      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.write_file({ "Ghost Author" => "55555" }, f.path)
        # Should not raise
        expect { described_class.update_names(f.path) }.not_to raise_error
      end
    end
  end

  # ---------------------------------------------------------------------------
  # .reconcile_names — stub external VIAF HTTP calls
  # ---------------------------------------------------------------------------
  describe ".reconcile_names" do
    let(:admin) { create(:admin) }

    before do
      # Prevent actual HTTP calls to VIAF
      allow(Name).to receive(:suggestions).and_return(
        results: [{ name: "Smith, John", viaf_id: "77777", score: 0.0 }],
        error: nil
      )
    end

    it "appends new names from DB to CSV and writes the file" do
      Name.create!(name: "Smith, John", is_author: true, created_by: admin, updated_by: admin)

      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.reconcile_names(f.path)
        rows = CSV.read(f.path)
        names_in_file = rows.map(&:first)
        expect(names_in_file).to include("Smith, John")
      end
    end

    it "reads an existing CSV and does not re-query names already present" do
      _existing_name = Name.create!(name: "Already, Known", is_author: true, created_by: admin, updated_by: admin)

      Tempfile.create(["viaf", ".csv"]) do |f|
        # Pre-populate the CSV with the name so reconcile skips it
        described_class.write_file({ "Already, Known" => "33333" }, f.path)

        expect(Name).not_to receive(:suggestions).with("Already, Known", anything)
        described_class.reconcile_names(f.path)
      end
    end

    it "sets viaf_id to -1 when no VIAF match found" do
      allow(Name).to receive(:suggestions).and_return(results: [], error: nil)
      Name.create!(name: "Nomatch, Author", is_author: true, created_by: admin, updated_by: admin)

      Tempfile.create(["viaf", ".csv"]) do |f|
        described_class.reconcile_names(f.path)
        rows = CSV.read(f.path)
        nomatch_row = rows.find { |r| r[0] == "Nomatch, Author" }
        expect(nomatch_row&.last).to eq("-1")
      end
    end
  end
end
