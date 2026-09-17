class DirectMessagesController < ApplicationController
  before_action :set_thread

  def create
    authorize @thread, :create_message?, policy_class: DirectMessageThreadPolicy

    message = @thread.direct_messages.new(message_params.merge(user: current_user, sent_by_band: true))

    if message.save
      redirect_to band_direct_message_thread_path(@band, @thread), notice: "Reply sent."
    else
      redirect_to band_direct_message_thread_path(@band, @thread), alert: message.errors.full_messages.to_sentence
    end
  end

  private

  def set_thread
    @band = Band.find(params[:band_id])
    @thread = @band.direct_message_threads.find(params[:direct_message_thread_id])
  end

  def message_params
    params.require(:direct_message).permit(:body)
  end
end
