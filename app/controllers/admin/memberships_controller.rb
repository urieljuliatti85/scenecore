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

  # Deliberately leaves billing alone: pausing is a moderation measure —
  # suspending access while something is looked into — not a decision about
  # the fan's money. Ending the payment is what #cancel is for.
  def pause
    authorize @membership, :pause?
    @membership.update!(status: :paused)
    redirect_to admin_memberships_path, notice: "Membership paused. Subscription billing is unaffected."
  end

  # Cancelling the membership without stopping the subscription behind it
  # would keep Stripe billing a fan who no longer has access, so both end
  # together (SubscriptionCanceller).
  def cancel
    authorize @membership, :cancel?

    SubscriptionCanceller.call(band: @membership.band, user: @membership.user)

    redirect_to admin_memberships_path, notice: "Membership cancelled, and any subscription billing for it stopped."
  rescue SubscriptionCanceller::Error => e
    redirect_to admin_memberships_path, alert: e.message
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
