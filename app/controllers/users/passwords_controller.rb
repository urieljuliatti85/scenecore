class Users::PasswordsController < Devise::PasswordsController
  # Requesting a reset sends mail to whatever address is submitted, so
  # without a limit this is a free email generator pointed at anyone —
  # a real cost since SMTP was configured, and a way to bury someone's
  # inbox using SceneCore's own sending reputation.
  #
  # See Users::SessionsController for why this keeps its own store.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)

  rate_limit to: 5, within: 1.hour, only: :create,
             store: RATE_LIMIT_STORE,
             with: -> { redirect_to new_user_password_path, alert: "Too many password reset requests. Please try again later." }
end
