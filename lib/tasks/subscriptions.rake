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
end
