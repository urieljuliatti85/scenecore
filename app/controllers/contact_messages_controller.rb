class ContactMessagesController < ApplicationController
  skip_before_action :authenticate_user!

  # An unauthenticated public write endpoint that sends mail, so without
  # a limit it is a free spam channel pointed at whoever reads
  # CONTACT_EMAIL.
  #
  # The limiter gets its own store rather than Rails.cache. Rails.cache
  # is :null_store in test and would make the limit silently do nothing
  # there — a protection that cannot be tested is one nobody notices
  # breaking. Counters are per process either way, so they reset on
  # deploy and a second web replica would double the effective limit;
  # that caveat is recorded in ROADMAP.md, Phase 13.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)

  rate_limit to: 5, within: 1.hour, only: :create,
             store: RATE_LIMIT_STORE,
             with: -> { redirect_to contact_path, alert: "Too many messages sent. Please try again later." }

  def new
    @contact_message = ContactMessage.new
  end

  def create
    @contact_message = ContactMessage.new(contact_message_params)

    if @contact_message.save
      deliver(@contact_message)
      redirect_to contact_path, notice: "Thanks — your message has been sent."
    else
      render :new, status: :unprocessable_entity
    end
  end

  private

  # The message is already stored, so a mail failure must not lose it or
  # show the sender an error for something that did reach us.
  def deliver(contact_message)
    return if ContactMailer.recipient.blank?

    ContactMailer.new_message(contact_message).deliver_later
  rescue StandardError => e
    Rails.logger.error("Contact message #{contact_message.id} stored but not emailed: #{e.class}")
    Sentry.capture_exception(e) if defined?(Sentry)
  end

  def contact_message_params
    params.require(:contact_message).permit(:name, :email, :band, :message)
  end
end
