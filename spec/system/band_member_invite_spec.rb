require "rails_helper"

RSpec.describe "Band member invitation", type: :system do
  # Known CI-only flake, not yet fixed after three targeted attempts:
  #   1. Longer Capybara.default_max_wait_time on CI (spec/rails_helper.rb)
  #   2. Waiting for the "Member added." flash before asserting
  #   3. An explicit have_select(..., selected: ...) wait between `select`
  #      and the submit click, in case the change event hadn't settled
  # None of these held up. Across CI runs, log/test.log shows a *different*
  # click silently failing to reach the server each time (sometimes
  # click_link "Add member", sometimes click_button "Add member") — this
  # points at something systemic with headless Chrome on the GitHub Actions
  # runner losing an occasional click, not a bug in one specific step of
  # this spec. Reliably green locally, every time.
  #
  # Not spending more time on it for now. The system-test CI job retries
  # the suite once on failure and keeps screenshots/log as an artifact from
  # the first attempt specifically so the next investigation has evidence
  # to start from. Do not mark this pending/skipped — that would just hide
  # the flake instead of leaving a trail to it.
  it "lets an administrator add a member who can see the band but not manage its members" do
    admin = create(:user, name: "Alice")
    new_member = create(:user, name: "Bob", email: "bob@example.com")
    band = create(:band, name: "The Testers")
    create(:band_membership, :administrator, band: band, user: admin)

    visit new_user_session_path
    fill_in "user_email", with: admin.email
    fill_in "user_password", with: admin.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")

    visit band_band_memberships_path(band)
    click_link "Add member"
    expect(page).to have_button("Add member")
    select new_member.email, from: "User"
    # Confirm the DOM has actually caught up with the selection before
    # clicking submit — on the CI runner's headless Chrome, clicking submit
    # immediately after `select` sometimes fires before the browser has
    # finished processing the select's change event, and the click is lost.
    expect(page).to have_select("User", selected: new_member.email)
    click_button "Add member"

    expect(page).to have_content("Member added.")
    expect(page).to have_content("Bob")

    Capybara.reset_sessions!
    visit new_user_session_path
    fill_in "user_email", with: new_member.email
    fill_in "user_password", with: new_member.password
    click_button "Log in"
    expect(page).to have_content("Signed in successfully")

    visit band_path(band)

    expect(page).to have_content("The Testers")
    expect(page).not_to have_link("Members")
  end
end
