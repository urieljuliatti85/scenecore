namespace :subscriptions do
  # Before SubscriptionCanceller existed, cancelling a membership from the
  # admin screen left the Stripe subscription running, so some fans are
  # still being charged for access they no longer have. These tasks find
  # and fix those.
  #
  # Reporting is the default and changes nothing. Cancelling is a separate
  # task because it moves real money and cannot be undone — a cancelled
  # Stripe subscription has to be recreated, not restored.
  desc "List subscriptions still billing for a membership that is no longer active"
  task orphaned: :environment do
    orphans = Subscription.orphaned.includes(:user, :band)

    if orphans.empty?
      puts "No orphaned subscriptions."
      next
    end

    puts "#{orphans.size} subscription(s) still billing without an active membership:"
    puts

    orphans.each do |subscription|
      membership = subscription.band.memberships.find_by(user: subscription.user)
      puts format(
        "  #%-5d %-28s %-22s %-11s membership: %-10s stripe: %s",
        subscription.id,
        subscription.user.email,
        subscription.band.name,
        subscription.level,
        membership&.status || "none",
        subscription.stripe_subscription_id || "—"
      )
    end

    puts
    puts "Monthly total still being charged: $#{format('%.2f', orphans.sum { |s| Membership::PRICES_IN_CENTS.fetch(s.level) } / 100.0)}"
    puts "Run `rake subscriptions:cancel_orphaned` to stop this billing."
  end

  desc "Cancel subscriptions still billing for a membership that is no longer active"
  task cancel_orphaned: :environment do
    orphans = Subscription.orphaned.includes(:user, :band)

    if orphans.empty?
      puts "No orphaned subscriptions."
      next
    end

    puts "Cancelling #{orphans.size} subscription(s)..."

    failures = orphans.filter_map do |subscription|
      SubscriptionCanceller.call(band: subscription.band, user: subscription.user)
      puts "  cancelled ##{subscription.id} (#{subscription.user.email} / #{subscription.band.name})"
      nil
    rescue SubscriptionCanceller::Error => e
      # One unreachable subscription should not stop the rest: every fan
      # left billing is money still being taken.
      puts "  FAILED ##{subscription.id}: #{e.message}"
      subscription.id
    end

    puts
    puts failures.empty? ? "All cancelled." : "Failed: #{failures.join(', ')} — re-run to retry."
  end

  # Subscriptions created before ADR-008's split was implemented charge the
  # full amount into SceneCore's own account, so the band receives nothing
  # for them. These tasks find and fix that.
  #
  # Reporting is the default. Applying the split is separate because it
  # changes where real money goes from the next invoice onward.
  desc "List active subscriptions still charging the full amount to SceneCore"
  task unsplit: :environment do
    unsplit = Subscription.where(status: Subscription::BILLING_STATUSES)
                          .where.not(stripe_subscription_id: nil)
                          .includes(:user, :band)

    if unsplit.empty?
      puts "No active subscriptions to check."
      next
    end

    ready, blocked = unsplit.partition { |s| s.band.payouts_ready? }

    puts "#{unsplit.size} active subscription(s):"
    puts "  #{ready.size} on bands ready to receive their share"
    puts "  #{blocked.size} on bands without a cleared Connect account"
    puts

    blocked.group_by(&:band).each do |band, subs|
      puts format("  BLOCKED  %-24s %s (%d subscription(s)) — %s",
                  band.name, band.stripe_connect_status, subs.size,
                  "band must finish Stripe onboarding first")
    end

    puts if blocked.any?
    puts "Run `rake subscriptions:apply_split` to split the #{ready.size} ready one(s)."
  end

  desc "Route active subscriptions to their band's connected account from the next invoice"
  task apply_split: :environment do
    candidates = Subscription.where(status: Subscription::BILLING_STATUSES)
                             .where.not(stripe_subscription_id: nil)
                             .includes(:user, :band)
                             .select { |s| s.band.payouts_ready? }

    if candidates.empty?
      puts "Nothing to split. Run `rake subscriptions:unsplit` to see why."
      next
    end

    puts "Applying the split to #{candidates.size} subscription(s)..."

    failures = candidates.filter_map do |subscription|
      StripeClient.instance.v1.subscriptions.update(
        subscription.stripe_subscription_id,
        {
          application_fee_percent: PlatformSetting.current.membership_fee_percentage,
          transfer_data: { destination: subscription.band.stripe_connect_account_id }
        }
      )
      puts "  split ##{subscription.id} (#{subscription.user.email} / #{subscription.band.name})"
      nil
    rescue Stripe::StripeError => e
      # One unreachable subscription should not stop the rest: every one
      # left unsplit is a band still receiving nothing.
      puts "  FAILED ##{subscription.id}: #{e.message}"
      subscription.id
    end

    puts
    puts failures.empty? ? "All split." : "Failed: #{failures.join(', ')} — re-run to retry."
    puts "Existing invoices are unaffected; the split applies from the next one."
  end
end
