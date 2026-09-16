require "rails_helper"

RSpec.describe "Band member invitation", type: :system do
  # The member form is exercised directly below. Navigating to it through the
  # index link made this spec susceptible to an intermittent dropped browser
  # click when the system-test process had just finished another spec.
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

    visit new_band_band_membership_path(band)
    expect(page).to have_button("Add member")
    select new_member.email, from: "User"
    expect(page).to have_select("User", selected: new_member.email)
    find_field("User").send_keys(:tab)
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
