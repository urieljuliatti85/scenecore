class TracksController < ApplicationController
  before_action :set_band
  before_action :set_track

  def edit
    authorize @track
  end

  def update
    authorize @track

    if @track.update(track_params)
      redirect_to band_path(@band), notice: "Track updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_track
    @track = Track.joins(:album).where(albums: { band_id: @band.id }).find(params[:id])
  end

  def track_params
    params.require(:track).permit(:title, :spotify_url)
  end
end
