class Admin::MembershipsController < Admin::BaseController
  def index
    @memberships = Membership.includes(:user, :band).order(created_at: :desc)
    @memberships = @memberships.where(level: params[:level]) if params[:level].present?
    @memberships = @memberships.where(status: params[:status]) if params[:status].present?
  end
end
