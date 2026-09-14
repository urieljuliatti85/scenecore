class Admin::AlbumsController < Admin::BaseController
  before_action :set_album, only: [ :unpublish ]

  def index
    @albums = Album.published.includes(:band).order(created_at: :desc)
  end

  def unpublish
    ActiveRecord::Base.transaction do
      @album.draft!
      @album.tracks.update_all(status: Track.statuses[:draft])
    end

    AdminActionLog.create!(actor: current_user, action: "moderate_unpublish_album", subject: @album)

    redirect_to admin_albums_path, notice: "Album unpublished."
  end

  private

  def set_album
    @album = Album.find(params[:id])
  end
end
