class AlbumsController < ApplicationController
  SPOTIFY_ID_FORMAT = /\A[a-zA-Z0-9]{22}\z/

  before_action :set_band
  before_action :set_album, only: [ :show, :edit, :update, :publish, :unpublish, :refetch_cover, :cover_from_url ]

  def new
    @album = @band.albums.new
    authorize @album
  end

  def show
    authorize @album

    @tracks = @album.tracks.order(:track_number)
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

  # Re-reads the cover from Spotify for an album that was imported from
  # it. Spotify's image URLs are not permanent, so an album imported a
  # while ago can end up with a dead or blank cover.
  def refetch_cover
    authorize @album, :update?

    if @album.spotify_id.blank?
      return redirect_to band_album_path(@band, @album),
                         alert: "This album was not imported from Spotify."
    end

    details = SpotifyClient.new.fetch_album(@album.spotify_id)

    if details.cover_image_url.blank?
      redirect_to band_album_path(@band, @album), alert: "Spotify has no cover for this album."
    else
      @album.update!(spotify_cover_url: details.cover_image_url)
      redirect_to band_album_path(@band, @album), notice: "Cover updated from Spotify."
    end
  rescue SpotifyClient::Error
    redirect_to band_album_path(@band, @album), alert: "Could not reach Spotify right now. Please try again."
  end

  # Attaches a cover from a URL the band supplies. The band picks the
  # image, so the rights question stays with whoever holds them; the app
  # never goes looking for artwork on its own.
  def cover_from_url
    authorize @album, :update?

    image = RemoteImageFetcher.new.call(params[:cover_url])
    @album.cover.attach(io: image.io, filename: image.filename, content_type: image.content_type)

    if @album.save
      redirect_to band_album_path(@band, @album), notice: "Cover updated."
    else
      redirect_to band_album_path(@band, @album), alert: @album.errors.full_messages.to_sentence
    end
  rescue RemoteImageFetcher::Error => e
    redirect_to band_album_path(@band, @album), alert: e.message
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
      @album.spotify_id = spotify_id
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
