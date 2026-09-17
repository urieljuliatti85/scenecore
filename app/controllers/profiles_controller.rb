class ProfilesController < ApplicationController
  TABS = %w[details subscriptions orders].freeze

  def show
    @user = current_user
    @tab = TABS.include?(params[:tab]) ? params[:tab] : TABS.first
    @subscriptions = current_user.subscriptions.includes(:band).order(created_at: :desc) if @tab == "subscriptions"
    @orders = current_user.orders.includes(:band, :order_items).order(created_at: :desc) if @tab == "orders"
  end

  def edit
    @user = current_user
  end

  def update
    if current_user.update(profile_params)
      redirect_to profile_path, notice: "Profile updated."
    else
      @user = current_user
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def profile_params
    params.require(:user).permit(:name, :email)
  end
end
