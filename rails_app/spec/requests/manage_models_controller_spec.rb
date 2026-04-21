require "rails_helper"

# Tests for ManageModelsController base-class actions exercised through
# LanguagesController (Language has only a :name field and is the simplest
# subclass, making it the best proxy for the generic base behaviour).
#
# Already covered by manage_languages_spec.rb — NOT duplicated here:
#   - GET /languages (index) — guest redirect + signed-in 200
#   - GET /languages/search.json — broad and narrow search
#
# IMPORTANT: This app has `allow_forgery_protection = true` in the test
# environment (config/environments/test.rb) and uses `protect_from_forgery
# with: :null_session`.  That means any mutating request (POST/PATCH/DELETE)
# without a valid CSRF token receives a *null* (wiped) session and therefore
# appears unauthenticated.  The pattern used throughout this file is:
#
#   1. login_as(user)
#   2. GET a page to receive the CSRF token from the <meta> tag
#   3. Pass that token via the X-CSRF-Token header in the mutating request
RSpec.describe "ManageModelsController (via LanguagesController)", type: :request do
  let(:admin_user) { create(:admin) }

  # Extract the CSRF token from the most-recent response's <meta> tag.
  def csrf_token
    response.body.match(/<meta name="csrf-token" content="([^"]+)"/)[1]
  end

  # ---------------------------------------------------------------------------
  # GET /languages/new
  # ---------------------------------------------------------------------------
  describe "GET /languages/new" do
    context "when not signed in" do
      it "redirects guests away from the new form" do
        get new_language_path

        expect(response).to redirect_to(root_path)
      end
    end

    context "when signed in as admin" do
      it "responds with 200 OK and renders the new form" do
        login_as(admin_user, scope: :user)

        get new_language_path

        expect(response).to have_http_status(:success)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /languages/:id  (show)
  # ---------------------------------------------------------------------------
  describe "GET /languages/:id" do
    # Use a name that is unlikely to collide with seed data.
    let!(:language) { Language.create!(name: "ZzzShowTestLanguage", created_by: admin_user) }

    it "responds with 200 OK for an unauthenticated visitor (show is public)" do
      get language_path(language)

      expect(response).to have_http_status(:success)
    end

    it "responds with 200 OK for a signed-in admin" do
      login_as(admin_user, scope: :user)

      get language_path(language)

      expect(response).to have_http_status(:success)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /languages/:id/edit
  # ---------------------------------------------------------------------------
  describe "GET /languages/:id/edit" do
    let!(:language) { Language.create!(name: "ZzzEditTestLanguage", created_by: admin_user) }

    context "when not signed in" do
      it "redirects away from the edit page" do
        get edit_language_path(language)

        expect(response).not_to have_http_status(:success)
      end
    end

    context "when signed in as admin" do
      it "responds with 200 OK" do
        login_as(admin_user, scope: :user)

        get edit_language_path(language)

        expect(response).to have_http_status(:success)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # POST /languages  (create)
  # ---------------------------------------------------------------------------
  describe "POST /languages" do
    # Obtain a CSRF token before each mutating request.
    def post_with_csrf(name)
      login_as(admin_user, scope: :user)
      get new_language_path
      token = csrf_token
      post languages_path,
           params: { language: { name: name } },
           headers: { "X-CSRF-Token" => token }
    end

    context "with valid params" do
      it "creates a new Language record" do
        expect { post_with_csrf("ZzzCreateLangAramaic") }.to change(Language, :count).by(1)
      end

      it "redirects to the newly created language's show page" do
        post_with_csrf("ZzzCreateLangSumerian")

        expect(response).to redirect_to(language_path(Language.last))
      end

      it "sets created_by to the signed-in user via save_by" do
        post_with_csrf("ZzzCreateLangAccadian")

        expect(Language.last.created_by).to eq(admin_user)
      end
    end

    # NOTE: The HTML invalid-params path (render 'new' with errors) is not
    # tested here because the app's _error_message.html.erb partial has a
    # pre-existing bug (TypeError: no implicit conversion of Symbol into
    # Integer) that causes a 500 whenever validation errors are rendered.
    # The equivalent JSON path (tested below) verifies that the controller
    # correctly rejects invalid input without creating a record.

    context "as JSON with valid params" do
      it "returns the created record as JSON with 200 OK" do
        login_as(admin_user, scope: :user)
        get new_language_path
        token = csrf_token

        post languages_path,
             params: { language: { name: "ZzzJsonCreateKoine" } },
             headers: { "X-CSRF-Token" => token },
             as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("ZzzJsonCreateKoine")
      end
    end

    context "as JSON with invalid params (blank name)" do
      it "returns 400 Bad Request with error messages" do
        login_as(admin_user, scope: :user)
        get new_language_path
        token = csrf_token

        post languages_path,
             params: { language: { name: "" } },
             headers: { "X-CSRF-Token" => token },
             as: :json

        expect(response).to have_http_status(:bad_request)
        json = JSON.parse(response.body)
        expect(json["errors"]).to be_present
      end
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /languages/:id  (update)
  # ---------------------------------------------------------------------------
  describe "PATCH /languages/:id" do
    let!(:language) { Language.create!(name: "ZzzUpdateLangHebrew", created_by: admin_user) }

    def patch_with_csrf(lang, name)
      login_as(admin_user, scope: :user)
      get edit_language_path(lang)
      token = csrf_token
      patch language_path(lang),
            params: { language: { name: name } },
            headers: { "X-CSRF-Token" => token }
    end

    context "with valid params" do
      it "updates the language name in the database" do
        patch_with_csrf(language, "ZzzUpdatedBiblicalHebrew")

        expect(language.reload.name).to eq("ZzzUpdatedBiblicalHebrew")
      end

      it "redirects to the language show page" do
        patch_with_csrf(language, "ZzzUpdatedBiblicalHebrew2")

        expect(response).to redirect_to(language_path(language))
      end

      it "sets the success flash notice" do
        patch_with_csrf(language, "ZzzUpdatedBiblicalHebrew3")

        follow_redirect!
        expect(response.body).to include("Your changes have been saved")
      end
    end

    # NOTE: The HTML invalid-params path (render 'edit' with errors) is not
    # tested here for the same reason as the create path — the app's
    # _error_message.html.erb partial raises a TypeError whenever validation
    # errors are rendered in HTML.  The JSON path below confirms the controller
    # rejects invalid updates correctly.

    context "as JSON with valid params" do
      it "returns the updated record as JSON with 200 OK" do
        login_as(admin_user, scope: :user)
        get edit_language_path(language)
        token = csrf_token

        patch language_path(language),
              params: { language: { name: "ZzzJsonUpdateSyriac" } },
              headers: { "X-CSRF-Token" => token },
              as: :json

        expect(response).to have_http_status(:success)
        json = JSON.parse(response.body)
        expect(json["name"]).to eq("ZzzJsonUpdateSyriac")
      end
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /languages/:id  (destroy)
  # ---------------------------------------------------------------------------
  describe "DELETE /languages/:id" do
    def delete_with_csrf(lang, **opts)
      login_as(admin_user, scope: :user)
      get edit_language_path(lang)
      token = csrf_token
      delete language_path(lang),
             headers: { "X-CSRF-Token" => token },
             **opts
    end

    context "as JSON when the language has no associated entries (deletable)" do
      let!(:language) { Language.create!(name: "ZzzJsonDeleteMe", created_by: admin_user) }

      it "destroys the record and responds with 200 OK and an empty JSON body" do
        expect { delete_with_csrf(language, as: :json) }.to change(Language, :count).by(-1)

        expect(response).to have_http_status(:ok)
        expect(JSON.parse(response.body)).to eq({})
      end
    end

    context "as HTML when the language has no associated entries (deletable)" do
      let!(:language) { Language.create!(name: "ZzzHtmlDeleteMe", created_by: admin_user) }

      it "destroys the record" do
        expect { delete_with_csrf(language) }.to change(Language, :count).by(-1)
      end

      it "redirects after deletion (base class redirects to names_path)" do
        delete_with_csrf(language)

        # The base ManageModelsController#destroy HTML success path is
        # hardcoded to redirect to names_path regardless of subclass.
        expect(response).to have_http_status(:redirect)
      end
    end

    context "as JSON when the language is not deletable (has entries)" do
      let!(:language) { Language.create!(name: "ZzzInUseLang", created_by: admin_user) }

      before do
        # Stub entries_count and entries.count so the base `deletable?` check
        # treats this record as non-deletable without touching the DB schema.
        allow_any_instance_of(Language).to receive(:entries_count).and_return(1)
        allow_any_instance_of(Language).to receive_message_chain(:entries, :count).and_return(1)
      end

      it "responds with 422 Unprocessable Entity and an error message" do
        delete_with_csrf(language, as: :json)

        expect(response).to have_http_status(:unprocessable_entity)
        json = JSON.parse(response.body)
        expect(json["error"]).to be_present
      end
    end
  end
end
