class AuthenticatedBlobsController < ActiveStorage::Blobs::RedirectController
  before_action :authorize_attachment!

  private

  def authorize_attachment!
    attachment = @blob.attachments.first
    head :not_found and return unless attachment

    head :not_found unless AttachmentVisibility.visible?(attachment.record, user: current_user)
  end
end
