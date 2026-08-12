class ReputationRequestMailer < ApplicationMailer
  def send_request(to:, subject:, body:)
    @body = body
    mail(to: to, subject: subject)
  end
end
