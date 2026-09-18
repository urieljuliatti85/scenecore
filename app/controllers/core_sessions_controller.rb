class CoreSessionsController < ApplicationController
  before_action :set_band
  before_action :set_core_session, only: [ :show, :edit, :update, :destroy, :publish, :unpublish ]

  def new
    @core_session = @band.core_sessions.new
    authorize @core_session
  end

  def show
    authorize @core_session
  end

  def create
    @core_session = @band.core_sessions.new(core_session_params)
    authorize @core_session

    if @core_session.save
      redirect_to band_path(@band), notice: "Core session created."
    else
      render :new, status: :unprocessable_entity
    end
  end

  def edit
    authorize @core_session
  end

  def update
    authorize @core_session

    if @core_session.update(core_session_params)
      redirect_to band_path(@band), notice: "Core session updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    authorize @core_session

    @core_session.destroy
    redirect_to band_path(@band), notice: "Core session deleted."
  end

  def publish
    authorize @core_session
    @core_session.published!

    redirect_to band_path(@band), notice: "Core session published."
  end

  def unpublish
    authorize @core_session
    @core_session.draft!

    redirect_to band_path(@band), notice: "Core session unpublished."
  end

  private

  def set_band
    @band = Band.find(params[:band_id])
  end

  def set_core_session
    @core_session = @band.core_sessions.find(params[:id])
  end

  def core_session_params
    params.require(:core_session).permit(:title, :session_type, :audience_level, :starts_at, :capacity, :description, :access_url)
  end
end
