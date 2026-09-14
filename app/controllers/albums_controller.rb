class AlbumsController < ApplicationController
  before_action :set_band

  def new
    @album = @band.albums.new
    authorize @album
  end

  def search
    authorize @band.albums.new, :search?

    results = SpotifyClient.new.search_albums(params[:q])
    render json: results.map(&:to_h)
  rescue SpotifyClient::Error
    render json: { error: "Spotify search is unavailable right now." }, status: :bad_gateway
  end

  def create
    @album = @band.albums.new
    authorize @album

    spotify_id = params[:spotify_album_id]
    if spotify_id.blank?
      @album.errors.add(:base, "Select an album from the search results.")
      return render :new, status: :unprocessable_entity
    end

    import_album(spotify_id)
  rescue SpotifyClient::Error
    @album.errors.add(:base, "Could not import this album from Spotify. Please try again.")
    render :new, status: :bad_gateway
  end

  private

  def import_album(spotify_id)
    details = SpotifyClient.new.fetch_album(spotify_id)

    ActiveRecord::Base.transaction do
      @album.title = details.name
      @album.save!

      details.tracks.each do |track|
        @album.tracks.create!(title: track.title, track_number: track.track_number, spotify_url: track.spotify_url)
      end
    end

    redirect_to band_path(@band), notice: "Album added."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def set_band
    @band = Band.find(params[:band_id])
  end
end
