require "rails_helper"

RSpec.describe "Authentication rate limiting", type: :request do
  # Both limiters keep counters in a module-level store, so one example's
  # requests would otherwise count against the next one's.
  before do
    Users::SessionsController::RATE_LIMIT_STORE.clear
    Users::PasswordsController::RATE_LIMIT_STORE.clear
  end

  describe "POST /users/sign_in" do
    let(:user) { create(:user, password: "password123") }

    it "signs in with the right password" do
      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(root_path)
    end

    it "blocks further attempts once the limit is reached" do
      11.times do
        post user_session_path, params: { user: { email: user.email, password: "wrong" } }
      end

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to match(/Too many sign-in attempts/)
    end

    # The point of the limit: it must stop an attacker walking many
    # accounts from one client, not just repeated failures on one login.
    it "counts attempts per client rather than per account" do
      10.times do |n|
        post user_session_path, params: { user: { email: "victim#{n}@example.com", password: "wrong" } }
      end

      post user_session_path, params: { user: { email: user.email, password: "password123" } }

      expect(response).to redirect_to(new_user_session_path)
      expect(flash[:alert]).to match(/Too many sign-in attempts/)
    end
  end

  describe "POST /users/password" do
    let(:user) { create(:user) }

    it "sends a reset email for a known address" do
      expect {
        post user_password_path, params: { user: { email: user.email } }
      }.to change { ActionMailer::Base.deliveries.size }.by(1)

      expect(response).to redirect_to(new_user_session_path)
    end

    # config.paranoid: an unknown address must get the same answer as a
    # known one, or password recovery becomes a way to discover which
    # addresses have accounts here.
    it "does not reveal whether an address has an account" do
      post user_password_path, params: { user: { email: user.email } }
      known = [ response.status, flash[:notice] ]

      Users::PasswordsController::RATE_LIMIT_STORE.clear

      post user_password_path, params: { user: { email: "nobody@example.com" } }
      unknown = [ response.status, flash[:notice] ]

      expect(unknown).to eq(known)
    end

    it "blocks further requests once the limit is reached" do
      6.times { post user_password_path, params: { user: { email: user.email } } }

      expect(response).to redirect_to(new_user_password_path)
      expect(flash[:alert]).to match(/Too many password reset requests/)
    end

    it "stops the endpoint being used to bury an inbox" do
      6.times { post user_password_path, params: { user: { email: user.email } } }

      expect(ActionMailer::Base.deliveries.size).to eq(5)
    end
  end
end
