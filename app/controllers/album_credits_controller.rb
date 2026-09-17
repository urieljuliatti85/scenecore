class AlbumCreditsController < ApplicationController
  before_action :set_album

  def create
    authorize @album.album_credits.new

    user = User.find_by(email: params[:email])

    if user.nil?
      return redirect_to edit_band_album_path(@band, @album), alert: "No user found with that email."
    end

    @credit = @album.album_credits.new(user: user)

    if @credit.save
      redirect_to edit_band_album_path(@band, @album), notice: "#{user.name} credited on this album."
    else
      redirect_to edit_band_album_path(@band, @album), alert: @credit.errors.full_messages.to_sentence
    end
  end

  def destroy
    @credit = @album.album_credits.find(params[:id])
    authorize @credit

    @credit.destroy
    redirect_to edit_band_album_path(@band, @album), notice: "Credit removed."
  end

  private

  def set_album
    @band = Band.find(params[:band_id])
    @album = @band.albums.find(params[:album_id])
  end
end
