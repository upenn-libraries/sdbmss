require "rails_helper"

RSpec.describe CatalogController, type: :controller do
  let(:admin_user) { create(:admin) }

  describe "#current_search_is_saveable?" do
    it "returns true for non-advanced search with query" do
      allow(controller).to receive(:current_user).and_return(admin_user)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(
        search_field: "all_fields",
        q: "manuscript"
      ))

      expect(controller.current_search_is_saveable?).to be(true)
    end

    it "returns false for non-advanced search without query/facets" do
      allow(controller).to receive(:current_user).and_return(admin_user)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(
        search_field: "all_fields",
        q: nil,
        f: nil
      ))

      expect(controller.current_search_is_saveable?).to be(false)
    end

    it "returns false for advanced search with no populated fields" do
      search_fields = {
        manuscript_id: double("FieldDef"),
        title: double("FieldDef")
      }
      advanced_query = double("AdvancedQuery", config: double("AdvancedConfig", search_fields: search_fields))

      allow(controller).to receive(:current_user).and_return(admin_user)
      allow(controller).to receive(:advanced_query).and_return(advanced_query)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(
        search_field: "advanced",
        manuscript_id: nil,
        title: ""
      ))

      expect(controller.current_search_is_saveable?).to be(false)
    end

    it "returns true for advanced search with one populated field" do
      search_fields = {
        manuscript_id: double("FieldDef"),
        title: double("FieldDef")
      }
      advanced_query = double("AdvancedQuery", config: double("AdvancedConfig", search_fields: search_fields))

      allow(controller).to receive(:current_user).and_return(admin_user)
      allow(controller).to receive(:advanced_query).and_return(advanced_query)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(
        search_field: "advanced",
        manuscript_id: "SDBM_MS_1",
        title: ""
      ))

      expect(controller.current_search_is_saveable?).to be(true)
    end

    it "returns false when there is no current user" do
      allow(controller).to receive(:current_user).and_return(nil)
      allow(controller).to receive(:params).and_return(ActionController::Parameters.new(
        search_field: "all_fields",
        q: "anything"
      ))

      expect(controller.current_search_is_saveable?).to be(false)
    end
  end
end
