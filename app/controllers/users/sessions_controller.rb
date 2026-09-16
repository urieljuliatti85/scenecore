class Users::SessionsController < Devise::SessionsController
  # Sign-in accepted unlimited attempts, so password brute-force was
  # viable against any account, a platform administrator's included.
  #
  # Keyed by IP rather than by the submitted email on purpose: locking a
  # named account is what Devise's :lockable does, and that is itself a
  # denial-of-service vector — anyone who knows an address could lock its
  # owner out at will. Limiting the client instead blocks the attacker
  # without giving them a way to block anybody else.
  #
  # The store is this controller's own rather than Rails.cache, which is
  # :null_store in test and would make the limit silently do nothing
  # there — a protection that cannot be tested is one nobody notices
  # breaking. Same reasoning as ContactMessagesController.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)

  rate_limit to: 10, within: 3.minutes, only: :create,
             store: RATE_LIMIT_STORE,
             with: -> { redirect_to new_user_session_path, alert: "Too many sign-in attempts. Please try again in a few minutes." }
end
