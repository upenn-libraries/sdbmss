require "rails_helper"

describe SolrSearchable do
  # Language uses `extend SolrSearchable`, so all methods are class-level.
  # It also overrides `.filters` to add extra filter fields.
  let(:host) { Language }

  # -----------------------------------------------------------------------
  # .fields / .filters / .dates
  # -----------------------------------------------------------------------

  describe ".fields" do
    it "returns an array of [label, field_name] pairs" do
      result = host.fields
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
      result.each do |pair|
        expect(pair.length).to eq(2)
      end
    end

    it "includes the default 'name' field" do
      names = host.fields.map(&:last)
      expect(names).to include("name")
    end
  end

  describe ".filters" do
    it "returns an array of [label, field_name] pairs" do
      result = host.filters
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
    end

    it "includes the base 'id', 'created_by', and 'updated_by' entries" do
      filter_names = host.filters.map(&:last)
      expect(filter_names).to include("id", "created_by", "updated_by")
    end

    it "includes the Language-specific overridden filters" do
      filter_names = host.filters.map(&:last)
      expect(filter_names).to include("reviewed", "entries_count", "problem")
    end
  end

  describe ".dates" do
    it "returns an array of [label, field_name] pairs" do
      result = host.dates
      expect(result).to be_an(Array)
      expect(result).not_to be_empty
    end

    it "includes 'created_at' and 'updated_at'" do
      date_names = host.dates.map(&:last)
      expect(date_names).to include("created_at", "updated_at")
    end
  end

  # -----------------------------------------------------------------------
  # .search_fields
  # -----------------------------------------------------------------------

  describe ".search_fields" do
    it "returns an Array" do
      expect(host.search_fields).to be_an(Array)
    end

    it "combines fields, filters, and dates" do
      combined = host.fields + host.filters + host.dates
      expect(host.search_fields).to eq(combined)
    end

    it "contains all field names from fields, filters, and dates" do
      all_names = host.search_fields.map(&:last)
      expect(all_names).to include("name")
      expect(all_names).to include("id", "created_by")
      expect(all_names).to include("created_at", "updated_at")
    end
  end

  # -----------------------------------------------------------------------
  # .params_for_search
  # -----------------------------------------------------------------------

  describe ".params_for_search" do
    it "returns an ActionController::Parameters instance" do
      params = ActionController::Parameters.new(name: "test")
      result = host.params_for_search(params)
      expect(result).to be_a(ActionController::Parameters)
    end

    it "permits field-named scalar values" do
      params = ActionController::Parameters.new(name: "Latin")
      result = host.params_for_search(params)
      expect(result[:name]).to eq("Latin")
    end

    it "permits field-named array values" do
      params = ActionController::Parameters.new(name: ["Latin", "Greek"])
      result = host.params_for_search(params)
      expect(result[:name]).to eq(["Latin", "Greek"])
    end

    it "strips non-field params" do
      params = ActionController::Parameters.new(name: "Latin", not_a_field: "evil")
      result = host.params_for_search(params)
      expect(result.to_h.keys).not_to include("not_a_field")
    end
  end

  # -----------------------------------------------------------------------
  # .filters_for_search
  # -----------------------------------------------------------------------

  describe ".filters_for_search" do
    it "returns an ActionController::Parameters instance" do
      params = ActionController::Parameters.new(reviewed: "1")
      result = host.filters_for_search(params)
      expect(result).to be_a(ActionController::Parameters)
    end

    it "permits known filter fields" do
      params = ActionController::Parameters.new(id: "42", reviewed: "1", entries_count: "5")
      result = host.filters_for_search(params)
      expect(result[:id]).to eq("42")
      expect(result[:reviewed]).to eq("1")
      expect(result[:entries_count]).to eq("5")
    end

    it "permits filter fields supplied as arrays" do
      params = ActionController::Parameters.new(id: ["1", "2"])
      result = host.filters_for_search(params)
      expect(result[:id]).to eq(["1", "2"])
    end

    it "strips params that are not in the filters list" do
      params = ActionController::Parameters.new(name: "Latin", random: "val")
      result = host.filters_for_search(params)
      expect(result.to_h.keys).not_to include("name", "random")
    end
  end

  # -----------------------------------------------------------------------
  # .dates_for_search
  # -----------------------------------------------------------------------

  describe ".dates_for_search" do
    it "returns an ActionController::Parameters instance" do
      params = ActionController::Parameters.new(created_at: "2023-01-01")
      result = host.dates_for_search(params)
      expect(result).to be_a(ActionController::Parameters)
    end

    it "permits known date fields" do
      params = ActionController::Parameters.new(created_at: "2023-01-01", updated_at: "2024-06-01")
      result = host.dates_for_search(params)
      expect(result[:created_at]).to eq("2023-01-01")
      expect(result[:updated_at]).to eq("2024-06-01")
    end

    it "permits date fields supplied as arrays" do
      params = ActionController::Parameters.new(created_at: ["2023-01-01", "2024-01-01"])
      result = host.dates_for_search(params)
      expect(result[:created_at]).to eq(["2023-01-01", "2024-01-01"])
    end

    it "strips params that are not date fields" do
      params = ActionController::Parameters.new(name: "Latin", created_at: "2023-01-01")
      result = host.dates_for_search(params)
      expect(result.to_h.keys).not_to include("name")
      expect(result[:created_at]).to eq("2023-01-01")
    end
  end

  # -----------------------------------------------------------------------
  # .options_for_search
  # -----------------------------------------------------------------------

  describe ".options_for_search" do
    it "returns an ActionController::Parameters instance" do
      params = ActionController::Parameters.new(name_option: "contains")
      result = host.options_for_search(params)
      expect(result).to be_a(ActionController::Parameters)
    end

    it "permits _option scalar params for all search fields" do
      option_params = {}
      host.search_fields.each do |pair|
        option_params["#{pair[1]}_option"] = "contains"
      end
      params = ActionController::Parameters.new(option_params)
      result = host.options_for_search(params)
      host.search_fields.each do |pair|
        expect(result["#{pair[1]}_option"]).to eq("contains")
      end
    end

    it "permits _option array params for all search fields" do
      option_params = {}
      host.search_fields.each do |pair|
        option_params["#{pair[1]}_option"] = ["contains", "exact"]
      end
      params = ActionController::Parameters.new(option_params)
      result = host.options_for_search(params)
      host.search_fields.each do |pair|
        expect(result["#{pair[1]}_option"]).to eq(["contains", "exact"])
      end
    end

    it "strips params that are not _option fields" do
      params = ActionController::Parameters.new(name_option: "contains", evil: "val")
      result = host.options_for_search(params)
      expect(result.to_h.keys).not_to include("evil")
    end
  end

  # -----------------------------------------------------------------------
  # .do_csv_dump  (filesystem I/O is stubbed)
  # -----------------------------------------------------------------------

  describe ".do_csv_dump" do
    let(:fake_record) do
      instance_double(Language,
        search_result_format: { id: 1, name: "Latin" }
      )
    end

    let(:fake_search_result) do
      double("search_result", results: [fake_record])
    end

    before do
      allow(host).to receive(:count).and_return(1)
      allow(host).to receive(:do_search).and_return(fake_search_result)

      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:delete)

      # Stub CSV.open to yield a spy so csv << … doesn't hit the filesystem
      csv_spy = []
      allow(csv_spy).to receive(:<<) { |row| csv_spy.push(row) }
      allow(CSV).to receive(:open).and_yield(csv_spy)

      # Stub Zip::File.open to avoid writing a real zip archive
      zip_spy = double("zip_file")
      allow(zip_spy).to receive(:add)
      allow(Zip::File).to receive(:open).and_yield(zip_spy)
    end

    it "calls do_search with limit equal to record count" do
      expect(host).to receive(:do_search).with(
        hash_including(limit: 1, offset: 0)
      ).and_return(fake_search_result)
      host.do_csv_dump
    end

    it "opens a CSV file with the pluralized model name" do
      expect(CSV).to receive(:open).with(
        %r{languages\.csv$}, "wb"
      ).and_yield([].tap { |a| allow(a).to receive(:<<) })
      host.do_csv_dump
    end

    it "creates a zip archive alongside the CSV" do
      expect(Zip::File).to receive(:open).with(
        %r{languages\.csv\.zip$}, Zip::File::CREATE
      ).and_yield(double("zip_file", add: nil))
      host.do_csv_dump
    end

    it "deletes the existing zip before writing if it exists" do
      allow(File).to receive(:exist?).with(%r{\.zip$}).and_return(true)
      expect(File).to receive(:delete).with(%r{\.zip$})
      host.do_csv_dump
    end

    it "deletes the plain CSV after zipping" do
      # The non-zip path: exist? returns true for the plain CSV after zip is done
      allow(File).to receive(:exist?).with(%r{[^z][^i][^p]$}).and_return(true)
      expect(File).to receive(:delete).with(%r{languages\.csv$})
      host.do_csv_dump
    end
  end

  # -----------------------------------------------------------------------
  # .do_csv_search  (filesystem I/O is stubbed)
  # -----------------------------------------------------------------------

  describe ".do_csv_search" do
    let(:fake_record) do
      instance_double(Language,
        search_result_format: { id: 1, name: "Latin" }
      )
    end

    let(:fake_search_result) do
      double("search_result", results: [fake_record])
    end

    let(:fake_user)     { double("user", username: "tester") }
    let(:fake_download) do
      double("download",
        id: 99,
        user: "tester",
        filename: "languages.csv",
        update: true
      )
    end

    let(:search_params) do
      ActionController::Parameters.new(name: "Latin")
    end

    before do
      allow(host).to receive(:count).and_return(1)
      allow(host).to receive(:do_search).and_return(fake_search_result)

      allow(File).to receive(:exist?).and_return(false)
      allow(File).to receive(:delete)

      csv_spy = []
      allow(csv_spy).to receive(:<<) { |row| csv_spy.push(row) }
      allow(CSV).to receive(:open).and_yield(csv_spy)

      zip_spy = double("zip_file")
      allow(zip_spy).to receive(:add)
      allow(Zip::File).to receive(:open).and_yield(zip_spy)
    end

    it "calls do_search with limit equal to record count and offset 0" do
      expect(host).to receive(:do_search).with(
        hash_including(limit: 1, offset: 0)
      ).and_return(fake_search_result)
      host.do_csv_search(search_params, fake_download)
    end

    it "writes a CSV file under tmp/ named with the download id, user, and filename" do
      expect(CSV).to receive(:open).with(
        "tmp/99_tester_languages.csv", "wb"
      ).and_yield([].tap { |a| allow(a).to receive(:<<) })
      host.do_csv_search(search_params, fake_download)
    end

    it "creates a zip archive at the expected path" do
      expect(Zip::File).to receive(:open).with(
        "tmp/99_tester_languages.csv.zip", Zip::File::CREATE
      ).and_yield(double("zip_file", add: nil))
      host.do_csv_search(search_params, fake_download)
    end

    it "updates the download status to 1 and appends .zip to the filename" do
      expect(fake_download).to receive(:update).with(
        { status: 1, filename: "languages.csv.zip" }
      )
      host.do_csv_search(search_params, fake_download)
    end

    it "deletes the plain CSV file after zipping when it exists" do
      allow(File).to receive(:exist?).with("tmp/99_tester_languages.csv").and_return(true)
      expect(File).to receive(:delete).with("tmp/99_tester_languages.csv")
      host.do_csv_search(search_params, fake_download)
    end
  end
end
