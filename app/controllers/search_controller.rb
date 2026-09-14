class SearchController < ApplicationController
  skip_before_action :authenticate_user!

  VALID_TYPES = %w[band album].freeze

  def index
    @type = VALID_TYPES.include?(params[:type]) ? params[:type] : "band"
    @query = params[:q].to_s.strip

    @results = if @query.present?
      @type == "album" ? search_albums : search_bands
    else
      []
    end
  end

  private

  def search_bands
    Band.approved.with_attached_photo.where("name ILIKE ?", sanitized_query)
  end

  def search_albums
    Album.published.joins(:band).where(bands: { status: :approved })
      .where("albums.title ILIKE ?", sanitized_query)
      .includes(:band)
  end

  def sanitized_query
    "%#{@query.gsub(/[%_]/) { |match| "\\#{match}" }}%"
  end
end
