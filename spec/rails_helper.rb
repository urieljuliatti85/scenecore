# This file is copied to spec/ when you run 'rails generate rspec:install'
require 'spec_helper'
ENV['RAILS_ENV'] ||= 'test'
require_relative '../config/environment'
# Prevent database truncation if the environment is production
abort("The Rails environment is running in production mode!") if Rails.env.production?
# Uncomment the line below in case you have `--require rails_helper` in the `.rspec` file
# that will avoid rails generators crashing because migrations haven't been run yet
# return unless Rails.env.test?
require 'rspec/rails'
require 'capybara/rspec'
require 'selenium-webdriver'
# Add additional requires below this line. Rails is not loaded until this point!

# --disable-dev-shm-usage makes Chrome use /tmp instead of the 64MB-capped
# /dev/shm that GitHub Actions containers impose. Cheap insurance against
# shm-pressure issues under headless Chrome, but NOT a confirmed fix for
# this project's CI system-spec flake (see band_member_invite_spec for
# what's actually known about it) — kept because it's harmless, not
# because it was proven to help. --no-sandbox is required for Chrome to
# run at all as root in a container.
#
# --window-size is explicit because without it, --headless=new on this
# GitHub Actions runner launches a small default viewport (confirmed via
# a failure screenshot: 780x437) that clips controls below the fold —
# in band_member_invite_spec's case, the "Add member" submit button.
# --headless=new appears to silently drop a click on an element outside
# the visible viewport instead of scrolling it into view first, which
# matches the flake's exact symptom (the click never reaches the server
# at all). This mirrors the fix already applied to
# ci_headless_chrome_mobile/mobile_navigation_spec for the same class of
# problem — a real window size fixed at launch instead of a runtime
# resize, which proved unreliable under --headless=new in this
# environment.
Capybara.register_driver :ci_headless_chrome do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=1280,1024")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# --window-size at launch, rather than resizing an already-open window,
# because Selenium's window.resize_to/CDP device-metrics overrides proved
# unreliable specifically under --headless=new in GitHub Actions' container
# (no real window manager) — a real phone-width window from the start
# sidesteps that class of flake entirely. Used by specs that need to assert
# on mobile-only UI (e.g. spec/system/mobile_navigation_spec.rb).
Capybara.register_driver :ci_headless_chrome_mobile do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--no-sandbox")
  options.add_argument("--disable-dev-shm-usage")
  options.add_argument("--disable-gpu")
  options.add_argument("--window-size=375,800")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

Capybara.register_driver :headless_chrome_mobile do |app|
  options = Selenium::WebDriver::Chrome::Options.new
  options.add_argument("--headless=new")
  options.add_argument("--window-size=375,800")
  Capybara::Selenium::Driver.new(app, browser: :chrome, options: options)
end

# Requires supporting ruby files with custom matchers and macros, etc, in
# spec/support/ and its subdirectories. Files matching `spec/**/*_spec.rb` are
# run as spec files by default. This means that files in spec/support that end
# in _spec.rb will both be required and run as specs, causing the specs to be
# run twice. It is recommended that you do not name files matching this glob to
# end with _spec.rb. You can configure this pattern with the --pattern
# option on the command line or in ~/.rspec, .rspec or `.rspec-local`.
#
# The following line is provided for convenience purposes. It has the downside
# of increasing the boot-up time by auto-requiring all files in the support
# directory. Alternatively, in the individual `*_spec.rb` files, manually
# require only the support files necessary.
#
# Rails.root.glob('spec/support/**/*.rb').sort_by(&:to_s).each { |f| require f }

# Ensures that the test database schema matches the current schema file.
# If there are pending migrations it will invoke `db:test:prepare` to
# recreate the test database by loading the schema.
# If you are not using ActiveRecord, you can remove these lines.
begin
  ActiveRecord::Migration.maintain_test_schema!
rescue ActiveRecord::PendingMigrationError => e
  abort e.to_s.strip
end
RSpec.configure do |config|
  config.include FactoryBot::Syntax::Methods
  config.include ActiveSupport::Testing::TimeHelpers
  config.include Devise::Test::IntegrationHelpers, type: :request
  config.include Devise::Test::IntegrationHelpers, type: :system

  config.before(:each, type: :system) do
    if ENV["CI"].present?
      driven_by :ci_headless_chrome
    else
      driven_by :selenium, using: :headless_chrome
    end
  end

  # CI runners are slower than a local machine (cold asset/bootsnap caches,
  # shared CPU), so give Capybara more room than its 2-second default before
  # giving up on a finder.
  Capybara.default_max_wait_time = 5 if ENV["CI"].present?

  # Remove this line if you're not using ActiveRecord or ActiveRecord fixtures
  config.fixture_paths = [
    Rails.root.join('spec/fixtures')
  ]

  # If you're not using ActiveRecord, or you'd prefer not to run each of your
  # examples within a transaction, remove the following line or assign false
  # instead of true.
  config.use_transactional_fixtures = true

  # You can uncomment this line to turn off ActiveRecord support entirely.
  # config.use_active_record = false

  # RSpec Rails uses metadata to mix in different behaviours to your tests,
  # for example enabling you to call `get` and `post` in request specs. e.g.:
  #
  #     RSpec.describe UsersController, type: :request do
  #       # ...
  #     end
  #
  # The different available types are documented in the features, such as in
  # https://rspec.info/features/8-0/rspec-rails
  #
  # You can also infer these behaviours automatically by location, e.g.
  # /spec/models would pull in the same behaviour as `type: :model` but this
  # behaviour is considered legacy and will be removed in a future version.
  #
  # To enable this behaviour uncomment the line below.
  # config.infer_spec_type_from_file_location!

  # Filter lines from Rails gems in backtraces.
  config.filter_rails_from_backtrace!
  # arbitrary gems may also be filtered via:
  # config.filter_gems_from_backtrace("gem name")
end
