class PagesController < ApplicationController
  skip_before_action :authenticate_user!, only: :home

  def home
    @featured_band = Band.featured.with_attached_photo.first
  end
end
