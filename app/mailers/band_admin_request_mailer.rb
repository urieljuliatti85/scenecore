class BandAdminRequestMailer < ApplicationMailer
  def approved(band_admin_request)
    @band_admin_request = band_admin_request
    @user = band_admin_request.band_membership.user
    @band = band_admin_request.band_membership.band

    mail(to: @user.email, subject: "You're now an administrator of #{@band.name}")
  end

  def rejected(band_admin_request)
    @band_admin_request = band_admin_request
    @user = band_admin_request.band_membership.user
    @band = band_admin_request.band_membership.band

    mail(to: @user.email, subject: "Your #{@band.name} administrator request")
  end
end
