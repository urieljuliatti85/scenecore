# The ordered steps a band works through before it is fully available on
# SceneCore: approved by the platform, with music, payments, and a first
# post. Read-only over existing state — this never writes to the band.
class BandOnboardingChecklist
  Step = Data.define(:key, :title, :body, :done, :cta_label, :cta_path)

  def self.call(band, view_context:)
    new(band, view_context: view_context).call
  end

  def initialize(band, view_context:)
    @band = band
    @view = view_context
  end

  def call
    [ approval_step, album_step, stripe_step, post_step ]
  end

  private

  def approval_step
    Step.new(
      key: "approval",
      title: "Get approved by SceneCore",
      body: "A platform administrator reviews every new band before its page goes public. " \
            "There's nothing to submit — your page opens to fans as soon as it's approved.",
      done: @band.approved?,
      cta_label: nil,
      cta_path: nil
    )
  end

  def album_step
    Step.new(
      key: "album",
      title: "Add your first release",
      body: "Bring an album over from Spotify, or add one by hand. Music is what the rest of the page is built around.",
      done: @band.albums.any?,
      cta_label: "Add album",
      cta_path: @view.new_band_album_path(@band)
    )
  end

  # Only the band's own administrator can reach Payments, so nobody else
  # is offered a link into it.
  def stripe_step
    can_manage = @view.policy(@band).manage_payments?

    Step.new(
      key: "stripe",
      title: "Connect Stripe to get paid",
      body: "Fans cannot start a membership or buy from your Store until Stripe has cleared your account.",
      done: @band.payouts_ready?,
      cta_label: ("Set up payments" if can_manage),
      cta_path: (@view.band_path(@band, tab: "payments") if can_manage)
    )
  end

  def post_step
    Step.new(
      key: "post",
      title: "Write to your followers",
      body: "A post is how the people following you hear from you directly, without an algorithm deciding who sees it.",
      done: @band.posts.any?,
      cta_label: "New post",
      cta_path: @view.new_band_post_path(@band)
    )
  end
end
