require "rails_helper"

RSpec.describe "Band member invitation", type: :system do
  # Known CI flake: on the GitHub Actions headless Chrome runner, either the
  # click_link "Add member" or the click_button "Add member" below has
  # intermittently failed to reach the server at all (confirmed via
  # log/test.log across two separate CI runs — no request logged for the
  # click that was lost, and it wasn't the same click both times). Reliably
  # green locally. Added an explicit `have_select(..., selected: ...)` wait
  # below in case the browser hadn't finished processing the select's
  # change event before the next click — untested against the real flake
  # yet. The system-test CI job retries the suite once on failure and keeps
  # screenshots/log as an artifact from the first attempt specifically to
  # make this failure mode investigable if it recurs; do not mark this
  # pending/skipped.
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
