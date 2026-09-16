class Admin::DashboardController < Admin::BaseController
  def index
    @pending_bands_count = Band.pending.count
    @bands_count = Band.count
    @users_count = User.count
  end
end
