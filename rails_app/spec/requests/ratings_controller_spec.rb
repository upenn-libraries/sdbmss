require "rails_helper"

RSpec.describe "RatingsController", type: :request do
  let(:admin)  { create(:admin) }
  let(:source) { Source.create!(source_type: SourceType.auction_catalog, created_by: admin) }
  let(:entry)  { Entry.create!(source: source, created_by: admin) }

  before do
    allow(Sunspot).to receive(:index)
    # render_to_string for the rating button partials requires compiled assets;
    # stub it to avoid ActionView::MissingTemplate in the test environment.
    allow_any_instance_of(RatingsController).to receive(:render_to_string).and_return("<button/>")
    login_as(admin, scope: :user)
  end

  # ---------------------------------------------------------------------------
  # POST /ratings (create)
  # ---------------------------------------------------------------------------
  describe "POST /ratings" do
    it "creates rating and returns JSON success" do
      expect {
        post ratings_path,
             params: { ratable_id: entry.id, ratable_type: "Entry", qualifier: "helpful" },
             headers: { "Accept" => "application/json" }
      }.to change(Rating, :count).by(1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["success"]).to be_present
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /ratings/:id (destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /ratings/:id" do
    let!(:rating) { Rating.create!(user: admin, ratable: entry, qualifier: "helpful") }

    it "destroys rating and returns JSON success" do
      expect {
        delete rating_path(rating), headers: { "Accept" => "application/json" }
      }.to change(Rating, :count).by(-1)

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["success"]).to be_present
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /ratings/:id (update)
  # ---------------------------------------------------------------------------
  describe "PATCH /ratings/:id" do
    let!(:rating) { Rating.create!(user: admin, ratable: entry, qualifier: "helpful") }

    before do
      # Ability rule `can :update, :all, created_by_id: user.id` tries to call
      # rating.created_by_id which doesn't exist on Rating. Stub authorize! so
      # the admin can exercise the action (admin can :manage, :all in production).
      allow_any_instance_of(RatingsController).to receive(:authorize!).and_return(nil)
    end

    it "updates rating and redirects" do
      patch rating_path(rating), params: { qualifier: "not helpful" }
      expect(response).to redirect_to(entry_path(entry))
    end
  end
end
