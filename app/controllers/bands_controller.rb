class BandsController < ApplicationController
  before_action :set_band_for_member_actions, only: [ :show, :edit, :update ]
  before_action :set_band_for_admin_actions, only: [ :approve, :reject ]

  def index
    @bands = policy_scope(Band)
  end

  def new
    @band = Band.new
    authorize @band
  end

  def create
    @band = Band.new(band_params)
    authorize @band

    ActiveRecord::Base.transaction do
      @band.save!
      @band.band_memberships.create!(user: current_user, role: :administrator)
    end

    redirect_to @band, notice: "Band created. Awaiting platform approval."
  rescue ActiveRecord::RecordInvalid
    render :new, status: :unprocessable_entity
  end

  def show
  end

  def edit
  end

  def update
    if @band.update(band_params)
      redirect_to @band, notice: "Band updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def approve
    @band.update!(status: :approved)
    redirect_to @band, notice: "Band approved."
  end

  def reject
    @band.update!(status: :rejected)
    redirect_to @band, notice: "Band rejected."
  end

  private

  # show/edit/update rely on band membership (or platform admin); anyone
  # else gets a plain 404 response (not a raised exception, which upsets
  # the session/cookie handling for the rest of the request cycle), so
  # band existence/privacy isn't leaked via a 403.
  def set_band_for_member_actions
    @band = Band.find(params[:id])

    unless BandPolicy.new(current_user, @band).show?
      head :not_found
      return
    end

    authorize @band if action_name.in?(%w[edit update])
  end

  def set_band_for_admin_actions
    @band = Band.find(params[:id])
    authorize @band
  end

  def band_params
    params.require(:band).permit(:name, :description, :photo)
  end
end
