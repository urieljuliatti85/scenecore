require "rails_helper"

RSpec.describe "Password resets", type: :request do
  it "accepts a reset request for an existing account" do
    user = create(:user)

    post user_password_path, params: { user: { email: user.email } }

    expect(response).to have_http_status(:see_other).or have_http_status(:found)
    expect(user.reload.reset_password_token).to be_present
  end

  # Devise delivers inline, so before User#send_devise_notification rescued,
  # an unreachable mail provider turned this into a 500 — a dead end for
  # someone who has simply forgotten their password.
  it "does not fail the request when the mail provider is unreachable" do
    user = create(:user)
    allow(Devise.mailer).to receive(:reset_password_instructions)
      .and_raise(Net::OpenTimeout, "execution expired")

    post user_password_path, params: { user: { email: user.email } }

    expect(response).to have_http_status(:see_other).or have_http_status(:found)
  end

  it "does not reveal whether an address has an account" do
    create(:user, email: "known@example.com")

    post user_password_path, params: { user: { email: "known@example.com" } }
    known_status = response.status

    post user_password_path, params: { user: { email: "unknown@example.com" } }

    expect(response.status).to eq(known_status)
  end
end
