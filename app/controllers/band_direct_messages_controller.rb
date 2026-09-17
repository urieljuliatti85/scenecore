class BandDirectMessagesController < ApplicationController
  # Own store rather than Rails.cache, same reasoning as
  # ContactMessagesController: Rails.cache is :null_store in test, which
  # would make this limit silently do nothing there. Counters are per
  # process, so they reset on deploy and a second web replica halves the
  # effective limit — an accepted tradeoff, not a bug.
  RATE_LIMIT_STORE = ActiveSupport::Cache::MemoryStore.new(size: 2.megabytes)

  rate_limit to: 1, within: 2.minutes, only: :create,
             store: RATE_LIMIT_STORE, by: -> { current_user.id },
             with: -> { redirect_to my_band_direct_messages_path(params[:slug]), alert: "Please wait a moment before sending another message." }

  before_action :set_band

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def show
    unless @band.memberships.find_by(user: current_user)&.can_access?(:core_member)
      return redirect_to public_band_path(@band.slug), alert: "Direct messages are a Core Member benefit."
    end

    @thread = @band.direct_message_threads.find_by(user: current_user)
  end

  def create
    unless @band.memberships.find_by(user: current_user)&.can_access?(:core_member)
      return redirect_to public_band_path(@band.slug), alert: "Direct messages are a Core Member benefit."
    end

    @thread = @band.direct_message_threads.find_or_create_by!(user: current_user)

    unless @thread.messageable_by_member?
      return redirect_to my_band_direct_messages_path(@band.slug), alert: "This band is not accepting messages from you right now."
    end

    message = @thread.direct_messages.new(message_params.merge(user: current_user, sent_by_band: false))

    if message.save
      redirect_to my_band_direct_messages_path(@band.slug), notice: "Message sent."
    else
      redirect_to my_band_direct_messages_path(@band.slug), alert: message.errors.full_messages.to_sentence
    end
  end

  private

  def set_band
    @band = Band.approved.find_by!(slug: params[:slug])
  end

  def message_params
    params.require(:direct_message).permit(:body)
  end
end
