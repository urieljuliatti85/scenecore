class AlbumsController < ApplicationController
  # Single source of truth lives on the model, which also validates it.
  SPOTIFY_ID_FORMAT = Album::SPOTIFY_ID_FORMAT

  before_action :set_band
  before_action :set_album, only: [ :show, :edit, :update, :publish, :unpublish, :refetch_cover, :cover_from_url ]

  def new
    @album = @band.albums.new
    authorize @album
  end

  def show
    authorize @album
  end

  def edit
    authorize @album
  end

  def update
    authorize @album

    spotify_id = params[:spotify_album_id]

    if spotify_id.present?
      return link_to_spotify(spotify_id)
    end

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
    return import_from_spotify(spotify_id) if spotify_id.present?
    return import_from_bandcamp if params.dig(:album, :bandcamp_embed_url).present?

    @album.errors.add(:base, "Select an album from the search results, or add one from Bandcamp.")
    render :new, status: :unprocessable_entity
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
    @album.published!

    redirect_to band_path(@band), notice: "Album published."
  end

  def unpublish
    authorize @album
    @album.draft!

    redirect_to band_path(@band), notice: "Album unpublished."
  end

  private

  # Points an existing album at a Spotify release: albums added before
  # spotify_id existed have no link, and the only other way to get one was
  # to delete the album and import it again, losing its publication state.
  #
  # Title is deliberately left alone. The band may have corrected it, and
  # this action is about attaching the link, not re-importing the record.
  def link_to_spotify(spotify_id)
    unless spotify_id.to_s.match?(SPOTIFY_ID_FORMAT)
      @album.errors.add(:base, "Select an album from the search results.")
      return render :edit, status: :unprocessable_entity
    end

    details = SpotifyClient.new.fetch_album(spotify_id)

    @album.spotify_id = spotify_id
    @album.spotify_cover_url = details.cover_image_url
    @album.save!

    redirect_to band_album_path(@band, @album), notice: "Album linked to Spotify."
  rescue SpotifyClient::Error
    @album.errors.add(:base, "Could not reach Spotify right now. Please try again.")
    render :edit, status: :bad_gateway
  rescue ActiveRecord::RecordInvalid
    render :edit, status: :unprocessable_entity
  end

  def import_from_spotify(spotify_id)
    unless spotify_id.to_s.match?(SPOTIFY_ID_FORMAT)
      @album.errors.add(:base, "Select an album from the search results.")
      return render :new, status: :unprocessable_entity
    end

    details = SpotifyClient.new.fetch_album(spotify_id)

    @album.title = details.name
    @album.spotify_id = spotify_id
    @album.spotify_cover_url = details.cover_image_url
    @album.save!

    redirect_to band_path(@band), notice: "Album added."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  # Bandcamp has no public search/import API like Spotify's, so the band
  # supplies the title and the embed URL directly rather than picking from
  # search results — see Album#bandcamp_embed_link for why that URL is
  # re-validated rather than trusted.
  def import_from_bandcamp
    @album.assign_attributes(title: params[:album][:title], bandcamp_embed_url: params[:album][:bandcamp_embed_url])

    if @album.save
      redirect_to band_path(@band), notice: "Album added."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_album
    @album = @band.albums.find(params[:id])
  end

  def album_params
    params.require(:album).permit(:cover, :early_access_level, :early_access_until, :bandcamp_embed_url)
  end
end
