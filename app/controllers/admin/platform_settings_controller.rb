class Admin::PlatformSettingsController < Admin::BaseController
  def edit
    @platform_setting = PlatformSetting.current
  end

  def update
    @platform_setting = PlatformSetting.current

    if @platform_setting.update(platform_setting_params)
      redirect_to edit_admin_platform_settings_path, notice: "Platform settings updated."
    else
      render :edit, status: :unprocessable_entity
    end
  end

  private

  def platform_setting_params
    params.require(:platform_setting).permit(
      :platform_fee_percentage, :terms_of_service_url, :privacy_policy_url,
      :support_email, :notification_sender_email, :band_signups_enabled
    )
  end
end
