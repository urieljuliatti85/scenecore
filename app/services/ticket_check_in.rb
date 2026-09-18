class TicketCheckIn
  AlreadyUsed = Class.new(StandardError)

  def self.call(ticket, validator:)
    ticket.with_lock do
      raise AlreadyUsed, "This ticket was already checked in." if ticket.used?

      ticket.update!(used_at: Time.current, checked_in_by: validator)
    end
  end
end
