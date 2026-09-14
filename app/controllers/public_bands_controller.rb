class PublicBandsController < ApplicationController
  skip_before_action :authenticate_user!

  def show
    @band = Band.approved.find_by!(slug: params[:slug])
  rescue ActiveRecord::RecordNotFound
    head :not_found
  end
end
