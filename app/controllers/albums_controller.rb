class AlbumsController < ApplicationController
  SPOTIFY_ID_FORMAT = /\A[a-zA-Z0-9]{22}\z/

  before_action :set_band
  before_action :set_album, only: [ :edit, :update, :publish, :unpublish ]

  def new
    @album = @band.albums.new
    authorize @album
  end

  def edit
    authorize @album
  end

  def update
    authorize @album

    if @album.update(album_params)
      redirect_to band_path(@band), notice: "Album updated."
    else
      render :edit, status: :unprocessable_entity
    end
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
    unless spotify_id.to_s.match?(SPOTIFY_ID_FORMAT)
      @album.errors.add(:base, "Select an album from the search results.")
      return render :new, status: :unprocessable_entity
    end

    import_album(spotify_id)
  rescue SpotifyClient::Error
    @album.errors.add(:base, "Could not import this album from Spotify. Please try again.")
    render :new, status: :bad_gateway
  end

  def publish
    authorize @album

    ActiveRecord::Base.transaction do
      @album.published!
      @album.tracks.where.not(spotify_url: [ nil, "" ]).update_all(status: Track.statuses[:published])
    end

    redirect_to band_path(@band), notice: "Album published."
  end

  def unpublish
    authorize @album

    ActiveRecord::Base.transaction do
      @album.draft!
      @album.tracks.update_all(status: Track.statuses[:draft])
    end

    redirect_to band_path(@band), notice: "Album unpublished."
  end

  private

  def import_album(spotify_id)
    details = SpotifyClient.new.fetch_album(spotify_id)

    ActiveRecord::Base.transaction do
      @album.title = details.name
      @album.spotify_cover_url = details.cover_image_url
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

  def set_album
    @album = @band.albums.find(params[:id])
  end

  def album_params
    params.require(:album).permit(:cover)
  end
end
