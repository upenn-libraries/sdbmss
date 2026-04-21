require "rails_helper"
require "sdbmss/similar_entries"

describe "SDBMSS::SimilarEntries" do
  describe SDBMSS::LevenshteinStringSet do
    it "returns neutral score when either set is empty" do
      non_empty = described_class.new(["Latin"])
      empty = described_class.new([])

      expect(non_empty - empty).to eq(5)
      expect(empty - non_empty).to eq(5)
    end

    it "returns lower score for close matches than distant matches" do
      target = described_class.new(["Confessiones"])
      close = described_class.new(["Confessiones"])
      far = described_class.new(["Geometry"])

      expect(target - close).to be <= (target - far)
    end
  end

  describe SDBMSS::Point do
    let(:admin_user) { create(:admin) }

    def create_entry_with_dimensions(source:, folios:, width:, height:, num_lines:, title:, language_name:)
      entry = create(
        :edit_test_entry,
        source: source,
        created_by: admin_user,
        approved: true,
        folios: folios,
        width: width,
        height: height,
        num_lines: num_lines
      )
      entry.entry_titles.create!(title: title, order: 0)
      entry.entry_languages.create!(language: Language.find_or_create_by!(name: language_name), order: 0)
      entry
    end

    it "computes zero distance for identical entry points" do
      source = create(:edit_test_source, created_by: admin_user)
      entry = create_entry_with_dimensions(
        source: source,
        folios: 120,
        width: 220,
        height: 320,
        num_lines: 30,
        title: "Confessiones",
        language_name: "Latin"
      )

      p1 = described_class.new(entry)
      p2 = described_class.new(entry)

      expect(p1 - p2).to eq(0)
    end

    it "computes greater distance for divergent entries" do
      source = create(:edit_test_source, created_by: admin_user)
      base = create_entry_with_dimensions(
        source: source,
        folios: 100,
        width: 210,
        height: 310,
        num_lines: 28,
        title: "Confessiones",
        language_name: "Latin"
      )
      distant = create_entry_with_dimensions(
        source: source,
        folios: 20,
        width: 80,
        height: 120,
        num_lines: 6,
        title: "Elementa",
        language_name: "Greek"
      )

      expect(described_class.new(base) - described_class.new(distant)).to be > 0
    end

    it "applies missing-value penalty when one point has blank dimensions" do
      source = create(:edit_test_source, created_by: admin_user)
      complete = create_entry_with_dimensions(
        source: source,
        folios: 90,
        width: 180,
        height: 260,
        num_lines: 24,
        title: "Dialogues",
        language_name: "Latin"
      )
      sparse = create(
        :edit_test_entry,
        source: source,
        created_by: admin_user,
        approved: true,
        folios: nil,
        width: nil,
        height: nil,
        num_lines: nil
      )

      expect(described_class.new(complete) - described_class.new(sparse)).to be > 0
    end
  end

  describe SDBMSS::SimilarEntries do
    let(:admin_user) { create(:admin) }

    it "sorts returned candidates by ascending distance and excludes self" do
      source = create(:edit_test_source, created_by: admin_user)
      subject_entry = create(
        :edit_test_entry,
        source: source,
        created_by: admin_user,
        approved: true,
        folios: 100,
        width: 210,
        height: 300,
        num_lines: 30
      )
      subject_entry.entry_titles.create!(title: "Confessiones", order: 0)
      subject_entry.entry_languages.create!(language: Language.find_or_create_by!(name: "Latin"), order: 0)

      near_entry = create(
        :edit_test_entry,
        source: source,
        created_by: admin_user,
        approved: true,
        folios: 101,
        width: 211,
        height: 301,
        num_lines: 30
      )
      near_entry.entry_titles.create!(title: "Confessiones", order: 0)
      near_entry.entry_languages.create!(language: Language.find_or_create_by!(name: "Latin"), order: 0)

      far_entry = create(
        :edit_test_entry,
        source: source,
        created_by: admin_user,
        approved: true,
        folios: 20,
        width: 70,
        height: 110,
        num_lines: 8
      )
      far_entry.entry_titles.create!(title: "Elementa", order: 0)
      far_entry.entry_languages.create!(language: Language.find_or_create_by!(name: "Greek"), order: 0)

      similar = described_class.new(subject_entry).to_a

      candidate_ids = similar.map { |row| row[:entry].id }

      expect(candidate_ids).to include(near_entry.id)
      expect(similar.map { |row| row[:entry].id }).not_to include(subject_entry.id)
      expect(candidate_ids).to all(be_in([near_entry.id, far_entry.id]))

      ordered_distances = similar.map { |row| row[:distance] }
      expect(ordered_distances).to eq(ordered_distances.sort)
    end

    it "returns no candidates when fallback candidate sets are too large" do
      source = create(:edit_test_source, created_by: admin_user)
      subject_entry = create(:edit_test_entry, source: source, created_by: admin_user, approved: true)

      relation = instance_double(ActiveRecord::Relation)
      allow(relation).to receive(:count).and_return(251)
      allow(relation).to receive(:+).and_return([])

      service = described_class.new(subject_entry)
      allow(service).to receive(:find_by_similar_dimenions).and_return(relation)
      allow(service).to receive(:find_by_provenance_dates).and_return([])

      expect(service.to_a).to eq([])
    end
  end
end
