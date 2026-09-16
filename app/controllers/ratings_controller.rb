class RatingsController < ApplicationController
  before_action :set_album

  rescue_from ActiveRecord::RecordNotFound do
    head :not_found
  end

  def upsert
    @rating = @album.ratings.find_or_initialize_by(user: current_user)
    authorize @rating

    if @rating.update(rating_params)
      redirect_to public_album_path(params[:slug], @album), notice: "Thanks for rating this album."
    else
      redirect_to public_album_path(params[:slug], @album), alert: @rating.errors.full_messages.to_sentence
    end
  end

  private

  def set_album
    band = Band.approved.find_by!(slug: params[:slug])
    @album = band.albums.published.find(params[:album_id])
  end

  def rating_params
    params.require(:rating).permit(:score)
  end
end
