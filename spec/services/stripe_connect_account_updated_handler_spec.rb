require "rails_helper"

RSpec.describe StripeConnectAccountUpdatedHandler do
  def stripe_account(id:, charges_enabled:, payouts_enabled:, disabled_reason: nil)
    instance_double(
      Stripe::Account,
      id: id,
      charges_enabled: charges_enabled,
      payouts_enabled: payouts_enabled,
      # A real StripeObject, not a verifying double: requirements'
      # fields are dynamic, so instance_double cannot verify them.
      requirements: Stripe::StripeObject.construct_from(disabled_reason: disabled_reason)
    )
  end

  describe ".call" do
    it "marks the band active once charges and payouts are both enabled" do
      band = create(:band, stripe_connect_account_id: "acct_1", stripe_connect_status: :onboarding)

      described_class.call(stripe_account(id: "acct_1", charges_enabled: true, payouts_enabled: true))

      expect(band.reload).to be_stripe_connect_active
      expect(band.store_open?).to be(true)
    end

    it "marks the band restricted when Stripe reports a disabled reason" do
      band = create(:band, stripe_connect_account_id: "acct_1", stripe_connect_status: :active)

      described_class.call(
        stripe_account(id: "acct_1", charges_enabled: true, payouts_enabled: true,
                       disabled_reason: "requirements.past_due")
      )

      expect(band.reload).to be_stripe_connect_restricted
      expect(band.store_open?).to be(false)
    end

    it "stays in onboarding while only charges are enabled" do
      band = create(:band, stripe_connect_account_id: "acct_1", stripe_connect_status: :onboarding)

      described_class.call(stripe_account(id: "acct_1", charges_enabled: true, payouts_enabled: false))

      expect(band.reload).to be_stripe_connect_onboarding
    end

    it "ignores an account that matches no band" do
      expect {
        described_class.call(stripe_account(id: "acct_unknown", charges_enabled: true, payouts_enabled: true))
      }.not_to raise_error
    end
  end
end
