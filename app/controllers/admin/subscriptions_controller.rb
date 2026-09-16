class Admin::SubscriptionsController < Admin::BaseController
  def index
    @subscriptions = Subscription.includes(:user, :band).order(created_at: :desc)
    @subscriptions = @subscriptions.where(level: params[:level]) if params[:level].present?
    @subscriptions = @subscriptions.where(status: params[:status]) if params[:status].present?
  end
end
