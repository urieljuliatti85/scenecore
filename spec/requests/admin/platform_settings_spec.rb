require "rails_helper"

RSpec.describe "Admin::PlatformSettings", type: :request do
  describe "GET /admin/platform_settings/edit" do
    it "shows the form for a platform admin" do
      admin = create(:user, :platform_admin)
      sign_in admin

      get edit_admin_platform_settings_path

      expect(response).to have_http_status(:ok)
    end

    it "returns 404 for a regular authenticated user" do
      user = create(:user)
      sign_in user

      get edit_admin_platform_settings_path

      expect(response).to have_http_status(:not_found)
    end

    it "requires authentication" do
      get edit_admin_platform_settings_path

      expect(response).to redirect_to(new_user_session_path)
    end
  end

  describe "PATCH /admin/platform_settings" do
    it "updates the settings for a platform admin" do
      admin = create(:user, :platform_admin)
      sign_in admin

      patch admin_platform_settings_path, params: { platform_setting: {
        membership_fee_percentage: "20",
        store_fee_percentage: "5",
        terms_of_service_url: "https://example.com/terms",
        privacy_policy_url: "https://example.com/privacy",
        support_email: "support@example.com",
        notification_sender_email: "noreply@example.com",
        band_signups_enabled: "0"
      } }

      expect(response).to redirect_to(edit_admin_platform_settings_path)
      setting = PlatformSetting.current
      expect(setting.membership_fee_percentage).to eq(20)
      expect(setting.store_fee_percentage).to eq(5)
      expect(setting.terms_of_service_url).to eq("https://example.com/terms")
      expect(setting.support_email).to eq("support@example.com")
      expect(setting.band_signups_enabled).to be false
    end

    it "rejects an invalid membership fee percentage" do
      admin = create(:user, :platform_admin)
      sign_in admin

      patch admin_platform_settings_path, params: { platform_setting: { membership_fee_percentage: "150" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(PlatformSetting.current.membership_fee_percentage).to eq(15)
    end

    it "rejects an invalid store fee percentage" do
      admin = create(:user, :platform_admin)
      sign_in admin

      patch admin_platform_settings_path, params: { platform_setting: { store_fee_percentage: "150" } }

      expect(response).to have_http_status(:unprocessable_content)
      expect(PlatformSetting.current.store_fee_percentage).to eq(10)
    end

    it "prevents a regular authenticated user from updating settings" do
      user = create(:user)
      sign_in user

      patch admin_platform_settings_path, params: { platform_setting: { membership_fee_percentage: "5" } }

      expect(response).to have_http_status(:not_found)
    end
  end
end
