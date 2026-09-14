class TracksController < ApplicationController
  before_action :set_band
  before_action :set_track, only: [ :edit, :update ]

  def new
    @track = @band.tracks.new
    authorize @track
  end

  def create
    @track = @band.tracks.new(track_params)
    authorize @track

    if @track.save
      redirect_to band_path(@band), notice: "Track created."
    else
      render :new, status: :unprocessable_entity
    end
  end

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
    @track = @band.tracks.find(params[:id])
  end

  def track_params
    params.require(:track).permit(:title, :spotify_url)
  end
end
