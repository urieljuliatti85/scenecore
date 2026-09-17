class CoreSessionRsvpsController < ApplicationController
  before_action :set_core_session

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def create
    unless @core_session.rsvpable_by?(current_user)
      return redirect_to public_band_path(params[:slug]), alert: "You can't RSVP to this session."
    end

    rsvp = @core_session.rsvps.new(user: current_user)

    if rsvp.save
      redirect_to public_band_path(params[:slug]), notice: "You're on the list for #{@core_session.title}."
    else
      redirect_to public_band_path(params[:slug]), alert: rsvp.errors.full_messages.to_sentence
    end
  end

  def destroy
    rsvp = @core_session.rsvps.find_by!(user: current_user)
    rsvp.destroy

    redirect_to public_band_path(params[:slug]), notice: "Your RSVP was cancelled."
  end

  private

  def set_core_session
    band = Band.approved.find_by!(slug: params[:slug])
    @core_session = band.core_sessions.published.find(params[:core_session_id])
  end
end
