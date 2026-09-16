class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: [ :home, :how_it_works, :support ]

  def home
    @featured_band = Band.featured.with_attached_photo.first
    @featured_albums = Album.published.joins(:band).where(bands: { status: :approved })
      .with_attached_cover.includes(:band).order(created_at: :desc).limit(3)
  end

  def how_it_works
  end

  def support
  end
end
