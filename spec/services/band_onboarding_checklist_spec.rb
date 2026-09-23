require "rails_helper"

RSpec.describe BandOnboardingChecklist do
  include Rails.application.routes.url_helpers

  # The spec stands in for the view, so it answers `policy` the way a
  # view does — for whoever is looking at the checklist.
  attr_accessor :viewer

  def policy(record)
    Pundit.policy!(viewer, record)
  end

  def steps_for(band)
    described_class.call(band, view_context: self).index_by(&:key)
  end

  it "lists the steps in the order the work happens" do
    expect(described_class.call(create(:band), view_context: self).map(&:key))
      .to eq(%w[approval album stripe post])
  end

  it "marks nothing done for a brand-new band" do
    expect(steps_for(create(:band)).values.map(&:done)).to all(be(false))
  end

  it "marks approval done only once the platform has approved the band" do
    expect(steps_for(create(:band, :approved))["approval"].done).to be(true)
    expect(steps_for(create(:band, :suspended))["approval"].done).to be(false)
    expect(steps_for(create(:band, :rejected))["approval"].done).to be(false)
  end

  it "gives approval no call to action, since the band cannot do it" do
    step = steps_for(create(:band))["approval"]

    expect(step.cta_label).to be_nil
    expect(step.cta_path).to be_nil
  end

  it "marks the release step done once the band has an album" do
    band = create(:band)
    create(:album, band: band)

    expect(steps_for(band)["album"].done).to be(true)
  end

  # An account id alone is not enough: an onboarding or restricted account
  # still cannot take money (ADR-007).
  it "marks Stripe done only when payouts are ready" do
    expect(steps_for(create(:band, :payouts_ready))["stripe"].done).to be(true)

    onboarding = create(:band, stripe_connect_status: :onboarding, stripe_connect_account_id: "acct_onboarding")
    expect(steps_for(onboarding)["stripe"].done).to be(false)
  end

  it "marks the post step done once the band has written a post" do
    band = create(:band)
    create(:post, band: band)

    expect(steps_for(band)["post"].done).to be(true)
  end

  it "points each actionable step at the page that completes it" do
    band = create(:band)
    self.viewer = create(:user)
    create(:band_membership, :administrator, band: band, user: viewer)
    steps = steps_for(band)

    expect(steps["album"].cta_path).to eq(new_band_album_path(band))
    expect(steps["stripe"].cta_path).to eq(band_path(band, tab: "payments"))
    expect(steps["post"].cta_path).to eq(new_band_post_path(band))
  end

  # Payments belong to the band's own administrator, so a platform admin
  # looking at First Steps is not offered a link they would be refused.
  it "offers no payments link to someone who cannot manage payments" do
    band = create(:band)
    self.viewer = create(:user, :platform_admin)

    step = steps_for(band)["stripe"]

    expect(step.cta_label).to be_nil
    expect(step.cta_path).to be_nil
  end
end
