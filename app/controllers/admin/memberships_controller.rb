class Admin::MembershipsController < Admin::BaseController
  before_action :set_membership, only: [ :edit, :update, :destroy, :pause, :cancel, :reactivate ]

  def index
    @memberships = Membership.includes(:user, :band).order(created_at: :desc)
    @memberships = @memberships.where(level: params[:level]) if params[:level].present?
    @memberships = @memberships.where(status: params[:status]) if params[:status].present?
  end

  def edit
    authorize @membership
  end

  def update
    authorize @membership

    if @membership.update(level_params)
      redirect_to admin_memberships_path, notice: "Membership updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def pause
    authorize @membership, :pause?
    @membership.update!(status: :paused)
    redirect_to admin_memberships_path, notice: "Membership paused."
  end

  def cancel
    authorize @membership, :cancel?
    @membership.update!(status: :cancelled)
    redirect_to admin_memberships_path, notice: "Membership cancelled."
  end

  def reactivate
    authorize @membership, :reactivate?
    @membership.update!(status: :active)
    redirect_to admin_memberships_path, notice: "Membership reactivated."
  end

  def destroy
    authorize @membership

    @membership.destroy
    redirect_to admin_memberships_path, notice: "Membership removed."
  end

  private

  def set_membership
    @membership = Membership.find(params[:id])
  end

  def level_params
    params.require(:membership).permit(:level)
  end
end
