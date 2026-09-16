class ContactMailer < ApplicationMailer
  # Where contact form messages are delivered. Without it the message is
  # still stored, so nothing is lost when this is unset.
  def self.recipient
    ENV["CONTACT_EMAIL"].presence
  end

  def new_message(contact_message)
    @contact_message = contact_message

    mail(
      to: self.class.recipient,
      subject: "SceneCore contact: #{contact_message.name}",
      # The sender is whoever filled the form, so replying goes to them
      # — but the From stays our own verified address, or the provider
      # would reject it as spoofing.
      reply_to: contact_message.email
    )
  end
end
