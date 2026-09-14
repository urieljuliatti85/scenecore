class Admin::BandsController < Admin::BaseController
  def index
    @bands = Band.all.order(created_at: :desc)
    @bands = @bands.where(status: params[:status]) if params[:status].present?
  end
end
