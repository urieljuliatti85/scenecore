require "rails_helper"

RSpec.describe "Band creation", type: :system do
  # Failed once in real CI (run 34849003460) with the same signature as the
  # known flake documented in band_member_invite_spec.rb: click_button
  # silently didn't submit. 30 consecutive local stress runs of this exact
  # flow (CI=true) never reproduced it, unlike the invite spec which
  # reproduces reliably when run as part of the full spec/system suite —
  # so whatever the underlying issue is, this spec is far less exposed to
  # it, not immune to it. See band_member_invite_spec.rb for what's
  # actually known about the root cause.
  it "lets a signed-up user create a band that starts out pending approval" do
    user = create(:user, name: "Alice")

    visit new_user_session_path
    fill_in "user_email", with: user.email
    fill_in "user_password", with: user.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")

    visit new_band_path
    fill_in "band_name", with: "The Testers"
    click_button "Create Band"

    expect(page).to have_content("The Testers")
    expect(page).to have_content(/pending/i)
  end
end
