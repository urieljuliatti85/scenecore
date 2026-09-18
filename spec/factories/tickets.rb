FactoryBot.define do
  factory :ticket do
    ticket_order { association :ticket_order, :paid }
    event { ticket_order.event }
    user { ticket_order.user }
  end
end
