require "rails_helper"

RSpec.describe "NotificationsController", type: :request do
  let(:user) { create(:user) }

  def make_notification(attrs = {})
    Notification.create!({
      user:    user,
      title:   "Test notification",
      message: "Something happened",
      active:  true,
      url:     "/dashboard"
    }.merge(attrs))
  end

  before { login_as(user, scope: :user) }

  # ---------------------------------------------------------------------------
  # GET /notifications
  # ---------------------------------------------------------------------------
  describe "GET /notifications" do
    it "responds with 200 and lists the user's notifications" do
      make_notification
      get notifications_path
      expect(response).to have_http_status(:ok)
    end
  end

  # ---------------------------------------------------------------------------
  # PATCH /notifications/:id
  # ---------------------------------------------------------------------------
  describe "PATCH /notifications/:id" do
    let!(:notification) { make_notification(active: true) }

    it "marks the notification as read (active: false) and returns JSON success" do
      patch notification_path(notification),
            params:  { active: false },
            as:      :json

      expect(response).to have_http_status(:ok)
      expect(JSON.parse(response.body)["success"]).to eq(true)
      expect(notification.reload.active).to eq(false)
    end
  end

  # ---------------------------------------------------------------------------
  # GET /notifications/read_many
  # ---------------------------------------------------------------------------
  describe "GET /notifications/read_many" do
    let!(:n1) { make_notification(active: true) }
    let!(:n2) { make_notification(active: true) }

    it "marks all specified notifications as read and redirects" do
      get read_many_notifications_path, params: { ids: [n1.id, n2.id], page: 0 }

      expect(response).to redirect_to(notifications_path(page: 0))
      expect(n1.reload.active).to eq(false)
      expect(n2.reload.active).to eq(false)
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /notifications/delete_many
  # ---------------------------------------------------------------------------
  describe "DELETE /notifications/delete_many" do
    let!(:n1) { make_notification }
    let!(:n2) { make_notification }

    it "destroys all specified notifications and redirects" do
      expect {
        delete delete_many_notifications_path, params: { ids: [n1.id, n2.id], page: 0 }
      }.to change(Notification, :count).by(-2)

      expect(response).to redirect_to(notifications_path(page: 0))
    end
  end

  # ---------------------------------------------------------------------------
  # DELETE /notifications/:id
  # ---------------------------------------------------------------------------
  describe "DELETE /notifications/:id" do
    let!(:notification) { make_notification }

    it "destroys the notification and redirects to the index" do
      expect {
        delete notification_path(notification)
      }.to change(Notification, :count).by(-1)

      expect(response).to redirect_to(notifications_path)
    end
  end
end
