FactoryBot.define do
  factory :band do
    sequence(:name) { |n| "Band #{n}" }
    description { "A great band." }
    status { :pending }

    # A band Stripe has cleared to receive money. Required for both Store
    # checkout and memberships, which route payment to the connected
    # account (ADR-007/ADR-008).
    trait :payouts_ready do
      stripe_connect_status { :active }
      sequence(:stripe_connect_account_id) { |n| "acct_test_#{n}" }
    end

    trait :approved do
      status { :approved }
    end

    trait :rejected do
      status { :rejected }
    end

    trait :suspended do
      status { :suspended }
    end
  end
end
