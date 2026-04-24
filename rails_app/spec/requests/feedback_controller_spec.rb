require "rails_helper"

RSpec.describe "FeedbackController", type: :request do
  # ---------------------------------------------------------------------------
  # POST /feedback (send_email)
  # ---------------------------------------------------------------------------
  describe "POST /feedback" do
    context "with subject and message" do
      before { allow(FeedbackMailer).to receive_message_chain(:feedback_email, :deliver_later) }

      it "delivers email and redirects to thanks" do
        post send_feedback_path,
             params: { subject: "Bug report", message: "Something broke" }

        expect(response).to redirect_to(feedback_thanks_path)
      end

      it "uses current_user email as from when not anonymous and logged in" do
        user = create(:user)
        login_as(user, scope: :user)

        expect(FeedbackMailer).to receive(:feedback_email)
          .with(user.email, anything, anything)
          .and_return(double(deliver_later: nil))

        post send_feedback_path,
             params: { subject: "Hi", message: "Hello" }
      end

      it "uses env from when anonymous flag set" do
        env_from = ENV.fetch("SDBMSS_EMAIL_FROM", "noreply@example.com")

        expect(FeedbackMailer).to receive(:feedback_email)
          .with(env_from, anything, anything)
          .and_return(double(deliver_later: nil))

        post send_feedback_path,
             params: { subject: "Hi", message: "Hello", anonymous: "1" }
      end
    end

    context "with missing subject or message" do
      it "renders index with errors" do
        post send_feedback_path, params: { subject: "", message: "" }

        expect(response).to have_http_status(:ok)
      end
    end
  end

  # ---------------------------------------------------------------------------
  # GET /feedback/thanks
  # ---------------------------------------------------------------------------
  describe "GET /feedback/thanks" do
    it "responds with 200" do
      get feedback_thanks_path
      expect(response).to have_http_status(:ok)
    end
  end
end
